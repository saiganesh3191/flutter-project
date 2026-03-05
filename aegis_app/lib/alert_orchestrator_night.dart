import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'risk_engine.dart';
import 'sensor_service.dart';

/// External side-effects (SMS/call/backend push). You implement this.
abstract class AlertSender {
  Future<void> sendEmergencyAlert({
    required DateTime at,
    required double lat,
    required double lon,
    required int score,
    required List<String> reasons,
  });
}

/// Alert state for UI
enum AlertStage { idle, arming, triggered, cooldown }

/// Night mode configuration
enum TimeMode { day, transition, night, peakNight }

class AlertPolicyConfig {
  const AlertPolicyConfig({
    this.highThreshold = 70,
    this.resetThreshold = 55,
    
    // Day mode settings
    this.requiredHighSamplesDay = 10, // ~1.5s
    this.minGyroForEvidenceDay = 1.5,
    this.minJerkForEvidenceDay = 12.0,
    this.cooldownDay = const Duration(seconds: 30),
    
    // Night mode settings (more sensitive)
    this.requiredHighSamplesNight = 8, // ~1.2s (faster)
    this.minGyroForEvidenceNight = 1.2, // 20% lower
    this.minJerkForEvidenceNight = 10.0, // 17% lower
    this.cooldownNight = const Duration(seconds: 60), // longer cooldown
    
    this.cancelWindow = const Duration(seconds: 8),
    
    // Night mode hours
    this.nightStartHour = 22, // 10 PM
    this.nightEndHour = 5,    // 5 AM
    this.peakNightStartHour = 23, // 11 PM
    this.peakNightEndHour = 4,    // 4 AM
  });

  final int highThreshold;
  final int resetThreshold;
  
  // Day mode
  final int requiredHighSamplesDay;
  final double minGyroForEvidenceDay;
  final double minJerkForEvidenceDay;
  final Duration cooldownDay;
  
  // Night mode
  final int requiredHighSamplesNight;
  final double minGyroForEvidenceNight;
  final double minJerkForEvidenceNight;
  final Duration cooldownNight;
  
  final Duration cancelWindow;
  
  // Time ranges
  final int nightStartHour;
  final int nightEndHour;
  final int peakNightStartHour;
  final int peakNightEndHour;
  
  /// Get current time mode
  TimeMode getTimeMode(DateTime time) {
    final hour = time.hour;
    
    // Peak night (11 PM - 4 AM) - most dangerous
    if (peakNightStartHour > peakNightEndHour) {
      if (hour >= peakNightStartHour || hour < peakNightEndHour) {
        return TimeMode.peakNight;
      }
    } else {
      if (hour >= peakNightStartHour && hour < peakNightEndHour) {
        return TimeMode.peakNight;
      }
    }
    
    // Night (10 PM - 5 AM)
    if (nightStartHour > nightEndHour) {
      if (hour >= nightStartHour || hour < nightEndHour) {
        return TimeMode.night;
      }
    } else {
      if (hour >= nightStartHour && hour < nightEndHour) {
        return TimeMode.night;
      }
    }
    
    // Transition (9-10 PM, 5-6 AM)
    if (hour == nightStartHour - 1 || hour == nightEndHour) {
      return TimeMode.transition;
    }
    
    // Day (6 AM - 9 PM)
    return TimeMode.day;
  }
  
  /// Get required samples based on time
  int getRequiredSamples(DateTime time) {
    final mode = getTimeMode(time);
    switch (mode) {
      case TimeMode.peakNight:
      case TimeMode.night:
        return requiredHighSamplesNight;
      case TimeMode.transition:
        return ((requiredHighSamplesDay + requiredHighSamplesNight) / 2).round();
      case TimeMode.day:
        return requiredHighSamplesDay;
    }
  }
  
  /// Get gyro threshold based on time
  double getGyroThreshold(DateTime time) {
    final mode = getTimeMode(time);
    switch (mode) {
      case TimeMode.peakNight:
      case TimeMode.night:
        return minGyroForEvidenceNight;
      case TimeMode.transition:
        return (minGyroForEvidenceDay + minGyroForEvidenceNight) / 2;
      case TimeMode.day:
        return minGyroForEvidenceDay;
    }
  }
  
  /// Get jerk threshold based on time
  double getJerkThreshold(DateTime time) {
    final mode = getTimeMode(time);
    switch (mode) {
      case TimeMode.peakNight:
      case TimeMode.night:
        return minJerkForEvidenceNight;
      case TimeMode.transition:
        return (minJerkForEvidenceDay + minJerkForEvidenceNight) / 2;
      case TimeMode.day:
        return minJerkForEvidenceDay;
    }
  }
  
  /// Get cooldown based on time
  Duration getCooldown(DateTime time) {
    final mode = getTimeMode(time);
    switch (mode) {
      case TimeMode.peakNight:
      case TimeMode.night:
        return cooldownNight;
      case TimeMode.transition:
        final dayMs = cooldownDay.inMilliseconds;
        final nightMs = cooldownNight.inMilliseconds;
        return Duration(milliseconds: ((dayMs + nightMs) / 2).round());
      case TimeMode.day:
        return cooldownDay;
    }
  }
}

class AlertStatus {
  const AlertStatus({
    required this.stage,
    required this.score,
    required this.reasons,
    required this.remainingCancelSeconds,
    required this.timeMode,
  });

  final AlertStage stage;
  final int score;
  final List<String> reasons;
  final int remainingCancelSeconds;
  final TimeMode timeMode;
}

/// Orchestrates alert triggering with night mode enhancement
class AlertOrchestratorNight {
  AlertOrchestratorNight({
    required SensorService sensorService,
    required AlertSender sender,
    AlertPolicyConfig config = const AlertPolicyConfig(),
  })  : _sensorService = sensorService,
        _sender = sender,
        _config = config;

  final SensorService _sensorService;
  final AlertSender _sender;
  final AlertPolicyConfig _config;

  StreamSubscription<RiskFrame>? _sub;

  final _statusController = StreamController<AlertStatus>.broadcast();
  Stream<AlertStatus> get statusStream => _statusController.stream;

  // state
  int _highCount = 0;
  bool _evidenceSeen = false;

  DateTime? _cooldownUntil;
  DateTime? _armingStartedAt;
  Timer? _armingTimer;

  bool _alertSentThisArm = false;

  // 🎯 HACKATHON-LEVEL: Evidence diversity tracking
  bool _gyroEvidenceSeen = false;
  bool _jerkEvidenceSeen = false;
  int _diverseEvidenceCount = 0;

  // persistence keys
  static const _kCooldownUntilMs = 'alert_cooldown_until_ms';

  Future<void> start() async {
    // load persisted cooldown
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kCooldownUntilMs);
    if (ms != null) {
      _cooldownUntil = DateTime.fromMillisecondsSinceEpoch(ms);
    }

    final now = DateTime.now();
    final mode = _config.getTimeMode(now);
    _emit(AlertStage.idle, score: 0, reasons: const [], remainingCancelSeconds: 0, timeMode: mode);

    _sub ??= _sensorService.riskStream.listen(_onFrame);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _armingTimer?.cancel();
    _armingTimer = null;
    _armingStartedAt = null;

    _resetStreak();
    final mode = _config.getTimeMode(DateTime.now());
    _emit(AlertStage.idle, score: 0, reasons: const [], remainingCancelSeconds: 0, timeMode: mode);
  }

  void dispose() {
    stop();
    _statusController.close();
  }

  /// User pressed "Cancel"
  void cancelArming() {
    if (_armingStartedAt == null) return;
    _armingTimer?.cancel();
    _armingTimer = null;
    _armingStartedAt = null;
    _alertSentThisArm = false;
    _resetStreak();
    final mode = _config.getTimeMode(DateTime.now());
    _emit(AlertStage.idle, score: 0, reasons: const ['Cancelled by user'], remainingCancelSeconds: 0, timeMode: mode);
  }

  bool _inCooldown(DateTime now) => _cooldownUntil != null && now.isBefore(_cooldownUntil!);

  void _onFrame(RiskFrame frame) async {
    final now = frame.sample.timestamp;
    final score = frame.assessment.score;
    final mode = _config.getTimeMode(now);

    if (_inCooldown(now)) {
      _emit(AlertStage.cooldown, score: score, reasons: const ['Cooldown'], remainingCancelSeconds: 0, timeMode: mode);
      return;
    }

    final isHigh = score >= _config.highThreshold;
    final isReset = score <= _config.resetThreshold;

    // Get dynamic thresholds based on time
    final gyroThreshold = _config.getGyroThreshold(now);
    final jerkThreshold = _config.getJerkThreshold(now);
    final requiredSamples = _config.getRequiredSamples(now);

    final hasEvidence = (frame.gyroMag >= gyroThreshold) || (frame.jerk >= jerkThreshold);

    // 🎯 HACKATHON-LEVEL: Track evidence diversity
    if (frame.gyroMag >= gyroThreshold) _gyroEvidenceSeen = true;
    if (frame.jerk >= jerkThreshold) _jerkEvidenceSeen = true;
    _diverseEvidenceCount = (_gyroEvidenceSeen ? 1 : 0) + (_jerkEvidenceSeen ? 1 : 0);

    // Debug logging with night mode info
    if (isHigh) {
      print('🔍 AlertOrch [${_getModeEmoji(mode)}]: score=$score, '
          'gyro=${frame.gyroMag.toStringAsFixed(2)}/$gyroThreshold, '
          'jerk=${frame.jerk.toStringAsFixed(2)}/$jerkThreshold, '
          'hasEvidence=$hasEvidence, diversity=$_diverseEvidenceCount/2, count=$_highCount/$requiredSamples');
    }

    if (isHigh) {
      // Only increment count if there's evidence in THIS frame
      if (hasEvidence) {
        _highCount++;
        _evidenceSeen = true;
        print('✅ Evidence found! Count++ = $_highCount');
      } else {
        // High score but no evidence - don't count it
        if (_highCount > 0) _highCount -= 1;
        print('⚠️ High score but NO evidence - count-- = $_highCount');
      }
    } else if (isReset) {
      _resetStreak();
      _stopArmingIfAny();
      _emit(AlertStage.idle, score: score, reasons: const [], remainingCancelSeconds: 0, timeMode: mode);
      return;
    } else {
      // mid zone: decay streak slowly
      if (_highCount > 0) _highCount -= 1;
    }

    final reasons = _buildReasons(frame, isHigh: isHigh, hasEvidence: hasEvidence, mode: mode, requiredSamples: requiredSamples);

    // 🎯 HACKATHON-LEVEL: Require diverse evidence for arming
    // Not just high score + motion, but MULTIPLE types of evidence
    final hasDiverseEvidence = _diverseEvidenceCount >= 2; // Both gyro AND jerk
    final readyToArm = (_highCount >= requiredSamples) && _evidenceSeen && hasDiverseEvidence;

    if (readyToArm) {
      print('🚨 READY TO ARM [${_getModeEmoji(mode)}]! count=$_highCount, evidenceSeen=$_evidenceSeen, diversity=$_diverseEvidenceCount/2');
    }

    if (!readyToArm) {
      _emit(AlertStage.idle, score: score, reasons: reasons, remainingCancelSeconds: 0, timeMode: mode);
      return;
    }

    // start arming countdown once
    if (_armingStartedAt == null && !_alertSentThisArm) {
      _armingStartedAt = now;
      _emit(AlertStage.arming, score: score, reasons: reasons, remainingCancelSeconds: _config.cancelWindow.inSeconds, timeMode: mode);

      _armingTimer?.cancel();
      _armingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final started = _armingStartedAt;
        if (started == null) return;

        final elapsed = DateTime.now().difference(started);
        final remaining = (_config.cancelWindow.inSeconds - elapsed.inSeconds).clamp(0, _config.cancelWindow.inSeconds);

        if (remaining > 0) {
          _emit(AlertStage.arming, score: score, reasons: reasons, remainingCancelSeconds: remaining, timeMode: mode);
          return;
        }

        // time is up -> trigger
        _armingTimer?.cancel();
        _armingTimer = null;

        if (_alertSentThisArm) return;
        _alertSentThisArm = true;

        // start cooldown (dynamic based on time)
        final cooldownDuration = _config.getCooldown(DateTime.now());
        _cooldownUntil = DateTime.now().add(cooldownDuration);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kCooldownUntilMs, _cooldownUntil!.millisecondsSinceEpoch);

        _emit(AlertStage.triggered, score: score, reasons: reasons, remainingCancelSeconds: 0, timeMode: mode);

        // send alert
        final lat = frame.sample.latitude;
        final lon = frame.sample.longitude;
        await _sender.sendEmergencyAlert(
          at: DateTime.now(),
          lat: lat,
          lon: lon,
          score: score,
          reasons: reasons,
        );

        // after firing, reset streak so it doesn't immediately re-arm
        _resetStreak();
        _armingStartedAt = null;
      });
    } else {
      // already arming, keep updating UI
      final started = _armingStartedAt!;
      final elapsed = now.difference(started);
      final remaining = (_config.cancelWindow.inSeconds - elapsed.inSeconds).clamp(0, _config.cancelWindow.inSeconds);
      _emit(AlertStage.arming, score: score, reasons: reasons, remainingCancelSeconds: remaining, timeMode: mode);
    }
  }

  void _stopArmingIfAny() {
    _armingTimer?.cancel();
    _armingTimer = null;
    _armingStartedAt = null;
    _alertSentThisArm = false;
  }

  void _resetStreak() {
    _highCount = 0;
    _evidenceSeen = false;
    _gyroEvidenceSeen = false;
    _jerkEvidenceSeen = false;
    _diverseEvidenceCount = 0;
  }

  String _getModeEmoji(TimeMode mode) {
    switch (mode) {
      case TimeMode.day:
        return '☀️ DAY';
      case TimeMode.transition:
        return '🌅 TRANSITION';
      case TimeMode.night:
        return '🌙 NIGHT';
      case TimeMode.peakNight:
        return '🌑 PEAK NIGHT';
    }
  }

  String _getModeName(TimeMode mode) {
    switch (mode) {
      case TimeMode.day:
        return 'Day Mode';
      case TimeMode.transition:
        return 'Transition';
      case TimeMode.night:
        return 'Night Mode';
      case TimeMode.peakNight:
        return 'Peak Night Mode';
    }
  }

  List<String> _buildReasons(RiskFrame frame, {required bool isHigh, required bool hasEvidence, required TimeMode mode, required int requiredSamples}) {
    final reasons = <String>[];

    // Add mode indicator
    reasons.add(_getModeName(mode));

    if (isHigh) reasons.add('High risk score');
    if (frame.assessment.state == RiskState.medium) reasons.add('Medium risk score');

    final gyroThreshold = _config.getGyroThreshold(frame.sample.timestamp);
    final jerkThreshold = _config.getJerkThreshold(frame.sample.timestamp);

    if (frame.gyroMag >= gyroThreshold) reasons.add('High rotation detected');
    if (frame.jerk >= jerkThreshold) reasons.add('Sudden movement detected');

    final hour = frame.sample.timestamp.hour;
    if (hour >= 22 || hour <= 5) reasons.add('Night time (enhanced mode)');

    if (_highCount > 0) reasons.add('Sustained: $_highCount/$requiredSamples');
    if (_evidenceSeen) reasons.add('Motion confirmed');

    if (!hasEvidence && isHigh) reasons.add('Score high but weak evidence');

    return reasons;
  }

  void _emit(AlertStage stage, {required int score, required List<String> reasons, required int remainingCancelSeconds, required TimeMode timeMode}) {
    _statusController.add(AlertStatus(
      stage: stage,
      score: score,
      reasons: reasons,
      remainingCancelSeconds: remainingCancelSeconds,
      timeMode: timeMode,
    ));
  }
}
