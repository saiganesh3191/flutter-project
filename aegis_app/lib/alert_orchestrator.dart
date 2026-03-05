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

class AlertPolicyConfig {
  const AlertPolicyConfig({
    this.highThreshold = 70,
    this.resetThreshold = 55,
    this.requiredHighSamples = 10, // ~1.5s at 150ms (safer than 8)
    this.cooldown = const Duration(seconds: 30),
    this.cancelWindow = const Duration(seconds: 8),

    this.minGyroForEvidence = 1.5,
    this.minJerkForEvidence = 12.0,
  });

  final int highThreshold;
  final int resetThreshold;
  final int requiredHighSamples;

  final Duration cooldown;
  final Duration cancelWindow;

  final double minGyroForEvidence;
  final double minJerkForEvidence;
}

class AlertStatus {
  const AlertStatus({
    required this.stage,
    required this.score,
    required this.reasons,
    required this.remainingCancelSeconds,
  });

  final AlertStage stage;
  final int score;
  final List<String> reasons;
  final int remainingCancelSeconds;
}

/// Orchestrates alert triggering with:
/// - persistence + hysteresis + evidence + cancel window + cooldown
class AlertOrchestrator {
  AlertOrchestrator({
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

  // persistence keys
  static const _kCooldownUntilMs = 'alert_cooldown_until_ms';

  Future<void> start() async {
    // load persisted cooldown
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kCooldownUntilMs);
    if (ms != null) {
      _cooldownUntil = DateTime.fromMillisecondsSinceEpoch(ms);
    }

    _emit(AlertStage.idle, score: 0, reasons: const [], remainingCancelSeconds: 0);

    _sub ??= _sensorService.riskStream.listen(_onFrame);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _armingTimer?.cancel();
    _armingTimer = null;
    _armingStartedAt = null;

    _resetStreak();
    _emit(AlertStage.idle, score: 0, reasons: const [], remainingCancelSeconds: 0);
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
    _emit(AlertStage.idle, score: 0, reasons: const ['Cancelled by user'], remainingCancelSeconds: 0);
  }

  bool _inCooldown(DateTime now) => _cooldownUntil != null && now.isBefore(_cooldownUntil!);

  void _onFrame(RiskFrame frame) async {
    final now = frame.sample.timestamp;
    final score = frame.assessment.score;

    if (_inCooldown(now)) {
      _emit(AlertStage.cooldown, score: score, reasons: const ['Cooldown'], remainingCancelSeconds: 0);
      return;
    }

    final isHigh = score >= _config.highThreshold;
    final isReset = score <= _config.resetThreshold;

    final hasEvidence = (frame.gyroMag >= _config.minGyroForEvidence) ||
        (frame.jerk >= _config.minJerkForEvidence);

    // Debug logging
    if (isHigh) {
      print('🔍 AlertOrch: score=$score, gyro=${frame.gyroMag.toStringAsFixed(2)}/${_config.minGyroForEvidence}, '
          'jerk=${frame.jerk.toStringAsFixed(2)}/${_config.minJerkForEvidence}, '
          'hasEvidence=$hasEvidence, count=$_highCount/${_config.requiredHighSamples}');
    }

    if (isHigh) {
      // Only increment count if there's evidence in THIS frame
      if (hasEvidence) {
        _highCount++;
        _evidenceSeen = true;
        print('✅ Evidence found! Count++ = $_highCount');
      } else {
        // High score but no evidence - don't count it
        // This prevents triggering on "soft" high scores
        if (_highCount > 0) _highCount -= 1;
        print('⚠️ High score but NO evidence - count-- = $_highCount');
      }
    } else if (isReset) {
      _resetStreak();
      _stopArmingIfAny();
      _emit(AlertStage.idle, score: score, reasons: const [], remainingCancelSeconds: 0);
      return;
    } else {
      // mid zone: decay streak slowly
      if (_highCount > 0) _highCount -= 1;
    }

    final reasons = _buildReasons(frame, isHigh: isHigh, hasEvidence: hasEvidence);

    // Arm when streak reaches threshold AND evidence seen at least once
    final readyToArm = (_highCount >= _config.requiredHighSamples) && _evidenceSeen;

    if (readyToArm) {
      print('🚨 READY TO ARM! count=$_highCount, evidenceSeen=$_evidenceSeen');
    }

    if (!readyToArm) {
      // not armed, just emit monitoring status
      _emit(AlertStage.idle, score: score, reasons: reasons, remainingCancelSeconds: 0);
      return;
    }

    // start arming countdown once
    if (_armingStartedAt == null && !_alertSentThisArm) {
      _armingStartedAt = now;
      _emit(AlertStage.arming, score: score, reasons: reasons, remainingCancelSeconds: _config.cancelWindow.inSeconds);

      _armingTimer?.cancel();
      _armingTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final started = _armingStartedAt;
        if (started == null) return;

        final elapsed = DateTime.now().difference(started);
        final remaining = (_config.cancelWindow.inSeconds - elapsed.inSeconds).clamp(0, _config.cancelWindow.inSeconds);

        if (remaining > 0) {
          _emit(AlertStage.arming, score: score, reasons: reasons, remainingCancelSeconds: remaining);
          return;
        }

        // time is up -> trigger
        _armingTimer?.cancel();
        _armingTimer = null;

        if (_alertSentThisArm) return;
        _alertSentThisArm = true;

        // start cooldown (persist it)
        _cooldownUntil = DateTime.now().add(_config.cooldown);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_kCooldownUntilMs, _cooldownUntil!.millisecondsSinceEpoch);

        _emit(AlertStage.triggered, score: score, reasons: reasons, remainingCancelSeconds: 0);

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
      // already arming, keep updating UI (optional)
      final started = _armingStartedAt!;
      final elapsed = now.difference(started);
      final remaining = (_config.cancelWindow.inSeconds - elapsed.inSeconds).clamp(0, _config.cancelWindow.inSeconds);
      _emit(AlertStage.arming, score: score, reasons: reasons, remainingCancelSeconds: remaining);
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
  }

  List<String> _buildReasons(RiskFrame frame, {required bool isHigh, required bool hasEvidence}) {
    final reasons = <String>[];

    if (isHigh) reasons.add('High risk score');
    if (frame.assessment.state == RiskState.medium) reasons.add('Medium risk score');

    if (frame.gyroMag >= _config.minGyroForEvidence) reasons.add('High rotation detected');
    if (frame.jerk >= _config.minJerkForEvidence) reasons.add('Sudden movement detected');

    final hour = frame.sample.timestamp.hour;
    if (hour >= 22 || hour <= 5) reasons.add('Night time');

    if (_highCount > 0) reasons.add('Sustained: $_highCount/${_config.requiredHighSamples}');
    if (_evidenceSeen) reasons.add('Motion confirmed');

    if (!hasEvidence && isHigh) reasons.add('Score high but weak evidence');

    return reasons;
  }

  void _emit(AlertStage stage, {required int score, required List<String> reasons, required int remainingCancelSeconds}) {
    _statusController.add(AlertStatus(
      stage: stage,
      score: score,
      reasons: reasons,
      remainingCancelSeconds: remainingCancelSeconds,
    ));
  }
}
