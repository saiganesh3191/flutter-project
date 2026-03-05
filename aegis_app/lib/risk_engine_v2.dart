import 'dart:collection';
import 'dart:math' as math;

/// Production-ready risk engine with:
/// 1. Location risk DISABLED (needs user configuration)
/// 2. Detailed logging for threshold tuning
/// 3. Sensor-based escalation (not sole decision maker)

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
    required this.contextRisk,
  });

  final double x, y, z;
  final double gx, gy, gz;
  final DateTime timestamp;
  final double latitude, longitude;
  final double contextRisk;

  double get magnitude => math.sqrt((x * x) + (y * y) + (z * z));
  double get deltaFromGravity => (magnitude - 9.81).abs();
  double get gyroMagnitude => math.sqrt((gx * gx) + (gy * gy) + (gz * gz));
}

class RiskConfig {
  const RiskConfig({
    this.gravityBaseline = 9.81,
    // Spike thresholds - TUNE THESE from logs
    this.spikeDeltaThreshold = 3.2,
    this.gyroSpikeThreshold = 3.5,
    this.persistenceSpikeCount = 3,
    this.persistenceWindow = const Duration(seconds: 4),
    this.persistenceGyroCount = 2,
    // Gyro-only detection
    this.enableGyroOnlyEvent = true,
    this.gyroOnlyMinCount = 3,
    this.gyroOnlyWindow = const Duration(seconds: 2),
    // Cooldown
    this.cooldownAfterHighRisk = const Duration(seconds: 10), // 10s for testing, 60s for production
    // Decay
    this.scoreDecayCheckInterval = const Duration(seconds: 2),
    this.scoreDecayStep = 4,
    this.decayAfterNoSpike = const Duration(seconds: 8),
    // Sampling
    this.minSampleInterval = const Duration(milliseconds: 120),
    // Time-based risk
    this.timeWeightStartHour = 22,
    this.timeWeightEndHour = 5,
    this.timeRiskWeightNight = 10,
    this.timeRiskWeightDay = 3,
    // LOCATION RISK DISABLED - needs real user configuration
    this.enableLocationRisk = false,
    this.locationRiskWeightInZone = 0,
    this.locationRiskWeightOutZone = 0,
    // Context
    this.contextMaxWeight = 15,
    // Movement weights
    this.highRiskBaseWeight = 28,
    this.mediumRiskBaseWeight = 18,
    this.lowRiskBaseWeight = 10,
    // Fusion boost
    this.confirmedFusionBoost = 8,
    this.maxEventIncrement = 45,
    // Logging
    this.enableDetailedLogging = true,
  });

  final double gravityBaseline;
  final double spikeDeltaThreshold;
  final double gyroSpikeThreshold;
  final int persistenceSpikeCount;
  final Duration persistenceWindow;
  final int persistenceGyroCount;
  final bool enableGyroOnlyEvent;
  final int gyroOnlyMinCount;
  final Duration gyroOnlyWindow;
  final Duration cooldownAfterHighRisk;
  final Duration scoreDecayCheckInterval;
  final int scoreDecayStep;
  final Duration decayAfterNoSpike;
  final Duration minSampleInterval;
  final int timeWeightStartHour;
  final int timeWeightEndHour;
  final int timeRiskWeightNight;
  final int timeRiskWeightDay;
  final bool enableLocationRisk;
  final int locationRiskWeightInZone;
  final int locationRiskWeightOutZone;
  final int contextMaxWeight;
  final int highRiskBaseWeight;
  final int mediumRiskBaseWeight;
  final int lowRiskBaseWeight;
  final int confirmedFusionBoost;
  final int maxEventIncrement;
  final bool enableDetailedLogging;
}

class RiskEventLog {
  const RiskEventLog({
    required this.timestamp,
    required this.message,
    required this.score,
    required this.state,
    this.accelDelta,
    this.gyroMag,
    this.accelSpikeCount,
    this.gyroSpikeCount,
  });

  final DateTime timestamp;
  final String message;
  final int score;
  final RiskState state;
  final double? accelDelta;
  final double? gyroMag;
  final int? accelSpikeCount;
  final int? gyroSpikeCount;
}

class RiskAssessment {
  const RiskAssessment({
    required this.score,
    required this.state,
    required this.inCooldown,
    this.maxAccelDelta,
    this.maxGyro,
    this.accelSpikeCount,
    this.gyroSpikeCount,
  });

  final int score;
  final RiskState state;
  final bool inCooldown;
  final double? maxAccelDelta;
  final double? maxGyro;
  final int? accelSpikeCount;
  final int? gyroSpikeCount;
}

class RiskEngine {
  RiskEngine({
    RiskConfig config = const RiskConfig(),
    void Function(RiskEventLog event)? eventLogger,
  })  : _config = config,
        _eventLogger = eventLogger;

  final RiskConfig _config;
  final void Function(RiskEventLog event)? _eventLogger;

  final Queue<DateTime> _accelSpikeTimestamps = Queue<DateTime>();
  final Queue<DateTime> _gyroSpikeTimestamps = Queue<DateTime>();

  int _score = 0;
  RiskState _state = RiskState.safe;
  DateTime? _lastSampleAt;
  DateTime? _lastSpikeAt;
  DateTime? _lastDecayCheckAt;
  DateTime? _cooldownUntil;

  // Tracking for tuning
  double _maxAccelDelta = 0.0;
  double _maxGyro = 0.0;

  RiskAssessment ingestSample(SensorSample sample) {
    if (_shouldSkipSample(sample.timestamp)) {
      return _snapshot(sample.timestamp);
    }

    _applyDecayIfNeeded(sample.timestamp);

    if (_isInCooldown(sample.timestamp)) {
      return _snapshot(sample.timestamp);
    }

    final accelSpike = _isAccelSpike(sample);
    final gyroSpike = _isGyroSpike(sample);

    // Track max values for tuning
    if (sample.deltaFromGravity > _maxAccelDelta) {
      _maxAccelDelta = sample.deltaFromGravity;
      if (_config.enableDetailedLogging) {
        print('📊 NEW MAX ACCEL DELTA: ${_maxAccelDelta.toStringAsFixed(2)} m/s²');
      }
    }
    if (sample.gyroMagnitude > _maxGyro) {
      _maxGyro = sample.gyroMagnitude;
      if (_config.enableDetailedLogging) {
        print('📊 NEW MAX GYRO: ${_maxGyro.toStringAsFixed(2)} rad/s');
      }
    }

    if (accelSpike || gyroSpike) {
      _lastSpikeAt = sample.timestamp;
    }

    if (accelSpike) {
      _accelSpikeTimestamps.addLast(sample.timestamp);
    }
    if (gyroSpike) {
      _gyroSpikeTimestamps.addLast(sample.timestamp);
    }

    _cleanupOldAccelSpikes(sample.timestamp);
    _cleanupOldGyroSpikes(sample.timestamp);

    // Log spike counts for tuning
    if (_config.enableDetailedLogging && (accelSpike || gyroSpike)) {
      print('📊 SPIKES: accel=${_accelSpikeTimestamps.length}, gyro=${_gyroSpikeTimestamps.length}, '
          'accelDelta=${sample.deltaFromGravity.toStringAsFixed(2)}, '
          'gyro=${sample.gyroMagnitude.toStringAsFixed(2)}');
    }

    // 1) Fusion-confirmed persistent pattern
    if (_hasPersistentFusionPattern()) {
      _onPersistentSpike(sample, fused: true);
      return _snapshot(sample.timestamp);
    }

    // 2) Accel-only persistent
    if (_hasPersistentAccelPattern()) {
      _onPersistentSpike(sample, fused: false);
      return _snapshot(sample.timestamp);
    }

    // 3) Gyro-only "snatch" event
    if (_config.enableGyroOnlyEvent && _hasGyroOnlyEvent(sample.timestamp)) {
      _onGyroOnlyEvent(sample);
      return _snapshot(sample.timestamp);
    }

    return _snapshot(sample.timestamp);
  }

  RiskAssessment _snapshot(DateTime now) {
    final next = _stateForScore(_score);
    if (next != _state) {
      _state = next;
      _log(
        now,
        'Risk state changed to ${_state.name.toUpperCase()}',
        accelDelta: _maxAccelDelta,
        gyroMag: _maxGyro,
        accelSpikeCount: _accelSpikeTimestamps.length,
        gyroSpikeCount: _gyroSpikeTimestamps.length,
      );
    }
    return RiskAssessment(
      score: _score,
      state: _state,
      inCooldown: _isInCooldown(now),
      maxAccelDelta: _maxAccelDelta,
      maxGyro: _maxGyro,
      accelSpikeCount: _accelSpikeTimestamps.length,
      gyroSpikeCount: _gyroSpikeTimestamps.length,
    );
  }

  bool _shouldSkipSample(DateTime now) {
    if (_lastSampleAt == null) {
      _lastSampleAt = now;
      return false;
    }
    final delta = now.difference(_lastSampleAt!);
    if (delta < _config.minSampleInterval) {
      return true;
    }
    _lastSampleAt = now;
    return false;
  }

  void _applyDecayIfNeeded(DateTime now) {
    if (_lastDecayCheckAt != null &&
        now.difference(_lastDecayCheckAt!) < _config.scoreDecayCheckInterval) {
      return;
    }
    _lastDecayCheckAt = now;
    if (_lastSpikeAt == null || now.difference(_lastSpikeAt!) >= _config.decayAfterNoSpike) {
      _score = math.max(0, _score - _config.scoreDecayStep);
    }
  }

  bool _isAccelSpike(SensorSample sample) {
    return sample.deltaFromGravity >= _config.spikeDeltaThreshold;
  }

  bool _isGyroSpike(SensorSample sample) {
    return sample.gyroMagnitude >= _config.gyroSpikeThreshold;
  }

  void _cleanupOldAccelSpikes(DateTime now) {
    while (_accelSpikeTimestamps.isNotEmpty &&
        now.difference(_accelSpikeTimestamps.first) > _config.persistenceWindow) {
      _accelSpikeTimestamps.removeFirst();
    }
  }

  void _cleanupOldGyroSpikes(DateTime now) {
    while (_gyroSpikeTimestamps.isNotEmpty &&
        now.difference(_gyroSpikeTimestamps.first) > _config.persistenceWindow) {
      _gyroSpikeTimestamps.removeFirst();
    }
  }

  bool _hasPersistentAccelPattern() {
    return _accelSpikeTimestamps.length >= _config.persistenceSpikeCount;
  }

  bool _hasPersistentFusionPattern() {
    return _accelSpikeTimestamps.length >= _config.persistenceSpikeCount &&
        _gyroSpikeTimestamps.length >= _config.persistenceGyroCount;
  }

  bool _hasGyroOnlyEvent(DateTime now) {
    while (_gyroSpikeTimestamps.isNotEmpty &&
        now.difference(_gyroSpikeTimestamps.first) > _config.gyroOnlyWindow) {
      _gyroSpikeTimestamps.removeFirst();
    }
    return _gyroSpikeTimestamps.length >= _config.gyroOnlyMinCount;
  }

  int _movementWeight(SensorSample sample) {
    final accelDelta = sample.deltaFromGravity;
    final gyro = sample.gyroMagnitude;

    int w;
    if (accelDelta >= 8) {
      w = _config.highRiskBaseWeight;
    } else if (accelDelta >= 5) {
      w = _config.mediumRiskBaseWeight;
    } else {
      w = _config.lowRiskBaseWeight;
    }

    if (gyro >= (_config.gyroSpikeThreshold * 1.6)) {
      w += 6;
    } else if (gyro >= (_config.gyroSpikeThreshold * 1.2)) {
      w += 3;
    }

    return w;
  }

  int _timeWeight(DateTime timestamp) {
    final hour = timestamp.hour;
    final isNight = _config.timeWeightStartHour > _config.timeWeightEndHour
        ? (hour >= _config.timeWeightStartHour || hour <= _config.timeWeightEndHour)
        : (hour >= _config.timeWeightStartHour && hour <= _config.timeWeightEndHour);
    return isNight ? _config.timeRiskWeightNight : _config.timeRiskWeightDay;
  }

  int _locationWeight(SensorSample sample) {
    // Location risk DISABLED - needs user configuration
    if (!_config.enableLocationRisk) {
      return 0;
    }
    return _config.locationRiskWeightOutZone;
  }

  int _contextWeight(SensorSample sample) {
    return (sample.contextRisk * _config.contextMaxWeight).round();
  }

  void _onPersistentSpike(SensorSample sample, {required bool fused}) {
    final movement = _movementWeight(sample);
    final time = _timeWeight(sample.timestamp);
    final location = _locationWeight(sample);
    final context = _contextWeight(sample);

    var increment = movement + time + location + context;
    if (fused) increment += _config.confirmedFusionBoost;
    increment = increment.clamp(0, _config.maxEventIncrement);

    _score = (_score + increment).clamp(0, 100);

    _accelSpikeTimestamps.clear();
    _gyroSpikeTimestamps.clear();

    _log(
      sample.timestamp,
      'Persistent spikes detected. fused=$fused increment=$increment '
      '[movement=$movement,time=$time,location=$location,context=$context]',
      accelDelta: sample.deltaFromGravity,
      gyroMag: sample.gyroMagnitude,
      accelSpikeCount: _config.persistenceSpikeCount,
      gyroSpikeCount: fused ? _config.persistenceGyroCount : 0,
    );

    if (_score >= 70) {
      _cooldownUntil = sample.timestamp.add(_config.cooldownAfterHighRisk);
      _log(
        sample.timestamp,
        'High-risk cooldown started for ${_config.cooldownAfterHighRisk.inSeconds}s',
      );
    }
  }

  void _onGyroOnlyEvent(SensorSample sample) {
    final time = _timeWeight(sample.timestamp);
    final location = _locationWeight(sample);
    final context = _contextWeight(sample);

    var increment = 14 + time + location + context;
    increment = increment.clamp(0, _config.maxEventIncrement);

    _score = (_score + increment).clamp(0, 100);

    _gyroSpikeTimestamps.clear();

    _log(
      sample.timestamp,
      'Gyro-only event detected. increment=$increment '
      '[time=$time,location=$location,context=$context]',
      gyroMag: sample.gyroMagnitude,
      gyroSpikeCount: _config.gyroOnlyMinCount,
    );

    if (_score >= 70) {
      _cooldownUntil = sample.timestamp.add(_config.cooldownAfterHighRisk);
      _log(
        sample.timestamp,
        'High-risk cooldown started for ${_config.cooldownAfterHighRisk.inSeconds}s',
      );
    }
  }

  bool _isInCooldown(DateTime now) {
    return _cooldownUntil != null && now.isBefore(_cooldownUntil!);
  }

  RiskState _stateForScore(int score) {
    if (score >= 70) return RiskState.high;
    if (score >= 40) return RiskState.medium;
    return RiskState.safe;
  }

  void _log(
    DateTime timestamp,
    String message, {
    double? accelDelta,
    double? gyroMag,
    int? accelSpikeCount,
    int? gyroSpikeCount,
  }) {
    _eventLogger?.call(
      RiskEventLog(
        timestamp: timestamp,
        message: message,
        score: _score,
        state: _stateForScore(_score),
        accelDelta: accelDelta,
        gyroMag: gyroMag,
        accelSpikeCount: accelSpikeCount,
        gyroSpikeCount: gyroSpikeCount,
      ),
    );
  }

  /// Reset max tracking values (call periodically for fresh tuning data)
  void resetMaxTracking() {
    _maxAccelDelta = 0.0;
    _maxGyro = 0.0;
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
