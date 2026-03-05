import 'dart:collection';
import 'dart:math' as math;

/// Risk severity states
enum RiskState { safe, medium, high }

class SensorSample {
  const SensorSample({
    required this.x,
    required this.y,
    required this.z,
    required this.gx,
    required this.gy,
    required this.gz,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.contextRisk, // [0..1]
  });

  final double x, y, z;
  final double gx, gy, gz;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double contextRisk;

  double get accelMagnitude => math.sqrt((x * x) + (y * y) + (z * z));
  double get gyroMagnitude => math.sqrt((gx * gx) + (gy * gy) + (gz * gz));
}

class GeoZone {
  const GeoZone({
    required this.centerLat,
    required this.centerLon,
    required this.radiusMeters,
  });

  final double centerLat;
  final double centerLon;
  final double radiusMeters;

  bool contains({required double lat, required double lon}) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat - centerLat);
    final dLon = _toRadians(lon - centerLon);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(centerLat)) *
            math.cos(_toRadians(lat)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;
    return distance <= radiusMeters;
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}

class RiskConfig {
  const RiskConfig({
    this.gravityBaseline = 9.81,
    this.window = const Duration(seconds: 4),

    // Spike thresholds
    this.spikeDeltaThreshold = 2.5,
    this.gyroSpikeThreshold = 3.0,
    this.jerkThreshold = 16.0,

    // Smoothing & decay
    this.scoreEmaAlpha = 0.22,
    this.scoreDecayPerSecond = 1.8,

    // engine cooldown (small; app policy should do the real gating)
    this.cooldownAfterHighRisk = const Duration(seconds: 10),

    // Time weights
    this.timeWeightStartHour = 22,
    this.timeWeightEndHour = 5,
    this.timeRiskWeightNight = 10,
    this.timeRiskWeightDay = 3,

    // Night mode multiplier (amplifies entire score at night)
    this.nightModeMultiplier = 1.5,      // 11 PM - 4 AM (peak danger)
    this.nightModeMultiplierLight = 1.3, // 10 PM - 11 PM, 4 AM - 5 AM
    this.peakNightStartHour = 23,        // 11 PM
    this.peakNightEndHour = 4,           // 4 AM

    // Location (optional)
    this.enableLocationRisk = false,
    this.locationRiskWeightInZone = 10,
    this.locationRiskWeightOutZone = 0,
    this.demoZone = const GeoZone(centerLat: 0.0, centerLon: 0.0, radiusMeters: 1000),

    // Context
    this.contextMaxWeight = 15,

    // Fusion boost
    this.confirmedFusionBoost = 10,

    // Guardrail
    this.minSampleInterval = const Duration(milliseconds: 120),
  });

  final double gravityBaseline;
  final Duration window;

  // Night mode multipliers
  final double nightModeMultiplier;
  final double nightModeMultiplierLight;
  final int peakNightStartHour;
  final int peakNightEndHour;

  final double spikeDeltaThreshold;
  final double gyroSpikeThreshold;
  final double jerkThreshold;

  final double scoreEmaAlpha;
  final double scoreDecayPerSecond;
  final Duration cooldownAfterHighRisk;

  final int timeWeightStartHour;
  final int timeWeightEndHour;
  final int timeRiskWeightNight;
  final int timeRiskWeightDay;

  final bool enableLocationRisk;
  final int locationRiskWeightInZone;
  final int locationRiskWeightOutZone;
  final GeoZone demoZone;

  final int contextMaxWeight;
  final int confirmedFusionBoost;

  final Duration minSampleInterval;
}

class RiskEventLog {
  const RiskEventLog({
    required this.timestamp,
    required this.message,
    required this.score,
    required this.state,
  });

  final DateTime timestamp;
  final String message;
  final int score;
  final RiskState state;
}

class RiskAssessment {
  const RiskAssessment({
    required this.score,
    required this.state,
    required this.inCooldown,
  });

  final int score;
  final RiskState state;
  final bool inCooldown;
}

class _WindowPoint {
  _WindowPoint({
    required this.t,
    required this.accelDelta,
    required this.gyroMag,
    required this.jerk,
  });

  final DateTime t;
  final double accelDelta;
  final double gyroMag;
  final double jerk;
}

class RiskEngine {
  RiskEngine({
    RiskConfig config = const RiskConfig(),
    void Function(RiskEventLog event)? eventLogger,
  })  : _config = config,
        _eventLogger = eventLogger;

  final RiskConfig _config;
  final void Function(RiskEventLog event)? _eventLogger;

  final Queue<_WindowPoint> _win = Queue<_WindowPoint>();

  double _scoreEma = 0.0;
  int _score = 0;
  RiskState _state = RiskState.safe;

  DateTime? _lastAcceptedSampleAt;
  DateTime? _lastDecayAt;
  DateTime? _cooldownUntil;

  // jerk based on accelDelta
  double _prevAccelDelta = 0.0;
  DateTime? _prevAccelAt;

  // 🎯 HACKATHON-LEVEL: Advanced false positive prevention
  final Queue<double> _accelHistory = Queue<double>();
  final Queue<double> _gyroHistory = Queue<double>();
  final Queue<double> _jerkHistory = Queue<double>();
  static const int _historySize = 20; // ~3 seconds at 150ms sampling
  
  // Adaptive baseline for anomaly detection
  double _baselineAccel = 9.81;
  double _baselineGyro = 0.0;
  int _baselineSamples = 0;
  static const int _baselineWindow = 50; // Learn from first 50 samples (~7.5s)

  RiskAssessment ingestSample(SensorSample sample) {
    _validateSample(sample);

    // always decay on wall clock
    _applyDecay(sample.timestamp);

    if (_shouldSkipSample(sample.timestamp)) {
      return _snapshot(sample.timestamp);
    }

    final inCooldown = _isInCooldown(sample.timestamp);
    if (inCooldown) {
      _lastAcceptedSampleAt = sample.timestamp;
      return _snapshot(sample.timestamp);
    }

    final accelDelta = (sample.accelMagnitude - _config.gravityBaseline).abs();
    final gyroMag = sample.gyroMagnitude;
    final jerk = _computeJerk(accelDelta, sample.timestamp);

    // 🎯 HACKATHON-LEVEL: Update history for pattern analysis
    _updateHistory(accelDelta, gyroMag, jerk);
    
    // 🎯 HACKATHON-LEVEL: Build adaptive baseline (first ~7.5 seconds)
    if (_baselineSamples < _baselineWindow) {
      _baselineAccel = ((_baselineAccel * _baselineSamples) + accelDelta) / (_baselineSamples + 1);
      _baselineGyro = ((_baselineGyro * _baselineSamples) + gyroMag) / (_baselineSamples + 1);
      _baselineSamples++;
    }

    _win.addLast(_WindowPoint(t: sample.timestamp, accelDelta: accelDelta, gyroMag: gyroMag, jerk: jerk));
    _cleanupWindow(sample.timestamp);

    // 🎯 HACKATHON-LEVEL: Apply false positive filters BEFORE scoring
    final falsePositiveCheck = _detectFalsePositive(accelDelta, gyroMag, jerk);
    if (falsePositiveCheck != null) {
      // This is likely a false positive - suppress score
      _scoreEma = math.max(0.0, _scoreEma - 5.0); // Decay faster
      _score = _scoreEma.round().clamp(0, 100);
      _lastAcceptedSampleAt = sample.timestamp;
      return _snapshot(sample.timestamp);
    }

    final instant = _computeInstantRisk(sample);

    // Apply night mode multiplier to instant score
    final nightMultiplier = _getNightModeMultiplier(sample.timestamp);
    final instantWithNight = (instant * nightMultiplier).clamp(0.0, 100.0);

    _scoreEma = (_config.scoreEmaAlpha * instantWithNight) + ((1.0 - _config.scoreEmaAlpha) * _scoreEma);
    _score = _scoreEma.round().clamp(0, 100);

    final next = _stateForScore(_score);
    if (next != _state) {
      _state = next;
      final modeStr = _getNightModeString(sample.timestamp);
      _log(sample.timestamp, 'Risk state -> ${_state.name} [$modeStr, mult=${nightMultiplier.toStringAsFixed(2)}x]');
    }

    if (_score >= 70) {
      _cooldownUntil = sample.timestamp.add(_config.cooldownAfterHighRisk);
      _log(sample.timestamp, 'Engine cooldown started (${_config.cooldownAfterHighRisk.inSeconds}s)');
    }

    _lastAcceptedSampleAt = sample.timestamp;
    return _snapshot(sample.timestamp);
  }

  /// Get night mode multiplier based on time
  double _getNightModeMultiplier(DateTime timestamp) {
    final hour = timestamp.hour;
    
    // Peak night (11 PM - 4 AM): 1.5x multiplier
    if (_config.peakNightStartHour > _config.peakNightEndHour) {
      if (hour >= _config.peakNightStartHour || hour < _config.peakNightEndHour) {
        return _config.nightModeMultiplier;
      }
    } else {
      if (hour >= _config.peakNightStartHour && hour < _config.peakNightEndHour) {
        return _config.nightModeMultiplier;
      }
    }
    
    // Light night (10 PM - 11 PM, 4 AM - 5 AM): 1.3x multiplier
    if (hour == _config.timeWeightStartHour || hour == _config.timeWeightEndHour) {
      return _config.nightModeMultiplierLight;
    }
    
    // Day: 1.0x (no multiplier)
    return 1.0;
  }

  String _getNightModeString(DateTime timestamp) {
    final mult = _getNightModeMultiplier(timestamp);
    if (mult >= _config.nightModeMultiplier) return '🌑 PEAK NIGHT';
    if (mult >= _config.nightModeMultiplierLight) return '🌙 NIGHT';
    return '☀️ DAY';
  }

  void _validateSample(SensorSample sample) {
    if (sample.contextRisk < 0 || sample.contextRisk > 1) {
      throw ArgumentError.value(sample.contextRisk, 'contextRisk', 'Must be in range [0, 1].');
    }
  }

  bool _shouldSkipSample(DateTime now) {
    if (_lastAcceptedSampleAt == null) return false;
    return now.difference(_lastAcceptedSampleAt!) < _config.minSampleInterval;
  }

  void _cleanupWindow(DateTime now) {
    while (_win.isNotEmpty && now.difference(_win.first.t) > _config.window) {
      _win.removeFirst();
    }
  }

  void _applyDecay(DateTime now) {
    if (_lastDecayAt == null) {
      _lastDecayAt = now;
      return;
    }
    final dtMs = now.difference(_lastDecayAt!).inMilliseconds;
    if (dtMs <= 0) return;

    final dtSec = dtMs / 1000.0;
    final decay = _config.scoreDecayPerSecond * dtSec;

    _scoreEma = math.max(0.0, _scoreEma - decay);
    _score = _scoreEma.round().clamp(0, 100);
    _lastDecayAt = now;
  }

  double _computeJerk(double accelDelta, DateTime now) {
    if (_prevAccelAt == null) {
      _prevAccelAt = now;
      _prevAccelDelta = accelDelta;
      return 0.0;
    }
    final dtMs = now.difference(_prevAccelAt!).inMilliseconds;
    if (dtMs <= 0) return 0.0;

    final dt = dtMs / 1000.0;
    final j = (accelDelta - _prevAccelDelta).abs() / dt;

    _prevAccelAt = now;
    _prevAccelDelta = accelDelta;
    return j;
  }

  double _computeInstantRisk(SensorSample sample) {
    if (_win.isEmpty) return 0.0;

    double maxAccelDelta = 0.0;
    double maxGyro = 0.0;
    double maxJerk = 0.0;

    int accelSpikes = 0, gyroSpikes = 0, jerkSpikes = 0;

    for (final p in _win) {
      if (p.accelDelta > maxAccelDelta) maxAccelDelta = p.accelDelta;
      if (p.gyroMag > maxGyro) maxGyro = p.gyroMag;
      if (p.jerk > maxJerk) maxJerk = p.jerk;

      if (p.accelDelta >= _config.spikeDeltaThreshold) accelSpikes++;
      if (p.gyroMag >= _config.gyroSpikeThreshold) gyroSpikes++;
      if (p.jerk >= _config.jerkThreshold) jerkSpikes++;
    }

    final accelScore = _scale(maxAccelDelta, inMin: 0, inMax: 10, outMax: 40);
    final gyroScore = _scale(maxGyro, inMin: 0, inMax: 8, outMax: 30);
    final jerkScore = _scale(maxJerk, inMin: 0, inMax: 40, outMax: 35);

    final persistence = (accelSpikes * 2) + (gyroSpikes * 3) + (jerkSpikes * 2);
    final persistenceScore = persistence.clamp(0, 25).toDouble();

    final hasAccel = accelSpikes >= 2;
    final hasGyro = gyroSpikes >= 2;
    final hasJerk = jerkSpikes >= 2;
    final fusionConfirmed = (hasAccel && hasGyro) || (hasAccel && hasJerk) || (hasGyro && hasJerk);
    final fusionBoost = fusionConfirmed ? _config.confirmedFusionBoost.toDouble() : 0.0;

    final timeW = _timeWeight(sample.timestamp).toDouble();
    final locW = _locationWeight(sample).toDouble();
    final ctxW = _contextWeight(sample).toDouble();

    double risk = 0.0;
    risk += accelScore + gyroScore + jerkScore;
    risk += persistenceScore + fusionBoost;
    risk += timeW + locW + ctxW;

    return risk.clamp(0.0, 100.0);
  }

  double _scale(double v, {required double inMin, required double inMax, required double outMax}) {
    if (v <= inMin) return 0.0;
    if (v >= inMax) return outMax;
    final t = (v - inMin) / (inMax - inMin);
    return t * outMax;
  }

  int _timeWeight(DateTime timestamp) {
    final hour = timestamp.hour;
    final isNight = _config.timeWeightStartHour > _config.timeWeightEndHour
        ? (hour >= _config.timeWeightStartHour || hour <= _config.timeWeightEndHour)
        : (hour >= _config.timeWeightStartHour && hour <= _config.timeWeightEndHour);
    return isNight ? _config.timeRiskWeightNight : _config.timeRiskWeightDay;
  }

  int _locationWeight(SensorSample sample) {
    if (!_config.enableLocationRisk) return 0;
    if (sample.latitude == 0.0 && sample.longitude == 0.0) return 0;
    final inZone = _config.demoZone.contains(lat: sample.latitude, lon: sample.longitude);
    return inZone ? _config.locationRiskWeightInZone : _config.locationRiskWeightOutZone;
  }

  int _contextWeight(SensorSample sample) {
    return (sample.contextRisk * _config.contextMaxWeight).round();
  }

  bool _isInCooldown(DateTime now) => _cooldownUntil != null && now.isBefore(_cooldownUntil!);

  RiskAssessment _snapshot(DateTime now) => RiskAssessment(
        score: _score,
        state: _state,
        inCooldown: _isInCooldown(now),
      );

  RiskState _stateForScore(int score) {
    if (score >= 70) return RiskState.high;
    if (score >= 40) return RiskState.medium;
    return RiskState.safe;
  }

  void _log(DateTime timestamp, String message) {
    _eventLogger?.call(RiskEventLog(
      timestamp: timestamp,
      message: message,
      score: _score,
      state: _stateForScore(_score),
    ));
  }

  // 🎯 HACKATHON-LEVEL: Advanced false positive detection methods

  /// Update rolling history for pattern analysis
  void _updateHistory(double accelDelta, double gyroMag, double jerk) {
    _accelHistory.addLast(accelDelta);
    _gyroHistory.addLast(gyroMag);
    _jerkHistory.addLast(jerk);

    while (_accelHistory.length > _historySize) _accelHistory.removeFirst();
    while (_gyroHistory.length > _historySize) _gyroHistory.removeFirst();
    while (_jerkHistory.length > _historySize) _jerkHistory.removeFirst();
  }

  /// Detect false positives using multiple validation layers
  /// Returns reason string if false positive detected, null if legitimate
  String? _detectFalsePositive(double accelDelta, double gyroMag, double jerk) {
    if (_accelHistory.length < 10) return null; // Need history first

    // Layer 1: Periodicity Detection (walking/running)
    final isPeriodic = _detectPeriodicity();
    if (isPeriodic) {
      return 'Periodic motion detected (walking/running)';
    }

    // Layer 2: Smooth Acceleration Profile (vehicle travel)
    final isSmoothAccel = _detectSmoothAcceleration();
    if (isSmoothAccel) {
      return 'Smooth acceleration detected (vehicle)';
    }

    // Layer 3: Low Variance (phone at rest or steady movement)
    final isLowVariance = _detectLowVariance();
    if (isLowVariance) {
      return 'Low variance detected (steady state)';
    }

    // Layer 4: Statistical Anomaly Check (must be 2+ sigma above baseline)
    final isAnomaly = _detectStatisticalAnomaly(accelDelta, gyroMag);
    if (!isAnomaly) {
      return 'Below statistical threshold (not anomalous)';
    }

    // All checks passed - this is likely legitimate
    return null;
  }

  /// Detect periodic patterns (walking = 1-2 Hz, running = 2-3 Hz)
  bool _detectPeriodicity() {
    if (_accelHistory.length < 15) return false;

    // Simple autocorrelation check
    // Walking has period of ~0.5-1.0 seconds (3-7 samples at 150ms)
    final list = _accelHistory.toList();
    int matches = 0;
    
    // Check for repeating pattern every 4-6 samples
    for (int lag = 4; lag <= 6; lag++) {
      double correlation = 0.0;
      for (int i = 0; i < list.length - lag; i++) {
        final diff = (list[i] - list[i + lag]).abs();
        if (diff < 1.5) correlation += 1.0; // Similar values
      }
      final corrRatio = correlation / (list.length - lag);
      if (corrRatio > 0.6) matches++; // 60% similarity
    }

    return matches >= 2; // At least 2 lags show periodicity
  }

  /// Detect smooth acceleration (vehicle travel)
  bool _detectSmoothAcceleration() {
    if (_jerkHistory.length < 10) return false;

    // Vehicle travel has low jerk (smooth acceleration)
    final avgJerk = _jerkHistory.reduce((a, b) => a + b) / _jerkHistory.length;
    final maxJerk = _jerkHistory.reduce(math.max);

    // Low average jerk AND low max jerk = smooth motion
    return avgJerk < 8.0 && maxJerk < 15.0;
  }

  /// Detect low variance (steady state or gentle movement)
  bool _detectLowVariance() {
    if (_accelHistory.length < 10) return false;

    final mean = _accelHistory.reduce((a, b) => a + b) / _accelHistory.length;
    final variance = _accelHistory.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / _accelHistory.length;
    final stdDev = math.sqrt(variance);

    // Low standard deviation = not much variation
    return stdDev < 1.0;
  }

  /// Statistical anomaly detection (Z-score)
  bool _detectStatisticalAnomaly(double accelDelta, double gyroMag) {
    if (_baselineSamples < _baselineWindow) return true; // Still learning, allow through

    // Calculate Z-scores
    final accelZScore = (accelDelta - _baselineAccel).abs() / math.max(0.5, _baselineAccel * 0.3);
    final gyroZScore = (gyroMag - _baselineGyro).abs() / math.max(0.3, _baselineGyro + 0.5);

    // Require at least 2-sigma deviation on BOTH metrics
    // This prevents single-axis false positives
    return accelZScore >= 2.0 && gyroZScore >= 1.5;
  }
}

// Legacy compatibility exports
enum RiskStatus { safe, medium, high }

class RiskResult {
  final int score;
  final RiskStatus status;
  final List<String> reasons;
  final bool highRiskTriggered;

  RiskResult({
    required this.score,
    required this.status,
    required this.reasons,
    this.highRiskTriggered = false,
  });
}
