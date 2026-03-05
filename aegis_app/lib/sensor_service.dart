import 'dart:async';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'risk_engine.dart';

/// Reads sensors + location and produces RiskAssessments + motion evidence.
/// NO alert sending here. That stays in AlertOrchestrator.
class SensorService {
  late final RiskEngine _riskEngine;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  Timer? _locationTimer;
  Timer? _sampleTimer;

  Position? _lastPosition;
  bool _isRunning = false;

  // raw sensor storage
  double _accelX = 0, _accelY = 0, _accelZ = 9.81;
  double _gyroX = 0, _gyroY = 0, _gyroZ = 0;

  // jerk tracking based on accelDelta (consistent with engine)
  double _prevAccelDelta = 0.0;
  DateTime? _prevAccelTs;

  // 🎯 HACKATHON-LEVEL: Performance monitoring
  int _sampleCount = 0;
  DateTime? _startTime;
  int _highRiskCount = 0;

  static const Duration sampleInterval = Duration(milliseconds: 150);
  static const Duration locationInterval = Duration(seconds: 20);

  final _riskStreamController = StreamController<RiskFrame>.broadcast();
  Stream<RiskFrame> get riskStream => _riskStreamController.stream;

  SensorService() {
    _riskEngine = RiskEngine(
      config: const RiskConfig(
        cooldownAfterHighRisk: Duration(seconds: 10),
        spikeDeltaThreshold: 2.5,
        gyroSpikeThreshold: 3.0,
        enableLocationRisk: false,
      ),
    );
  }

  Position? get lastPosition => _lastPosition;
  bool get isRunning => _isRunning;

  Future<void> ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw StateError('Location services disabled.');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) throw StateError('Location permission denied.');
    if (permission == LocationPermission.deniedForever) throw StateError('Location permission denied forever.');
  }

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    _prevAccelTs = null;
    _prevAccelDelta = 0.0;
    _sampleCount = 0;
    _startTime = DateTime.now();
    _highRiskCount = 0;

    print('🚀 SensorService: Starting monitoring...');

    _accelerometerSubscription = accelerometerEvents.listen((event) {
      _accelX = event.x;
      _accelY = event.y;
      _accelZ = event.z;
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((event) {
      _gyroX = event.x;
      _gyroY = event.y;
      _gyroZ = event.z;
    });

    _startSampling();
    _startLocationUpdates();
  }

  void stop() {
    _isRunning = false;

    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;

    _sampleTimer?.cancel();
    _sampleTimer = null;

    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void dispose() {
    stop();
    _riskStreamController.close();
  }

  void _startSampling() {
    _sampleTimer = Timer.periodic(sampleInterval, (_) => _processSample());
  }

  void _processSample() {
    if (!_isRunning) return;

    final now = DateTime.now();
    final position = _lastPosition;

    final accelMag = _mag3(_accelX, _accelY, _accelZ);
    final accelDelta = (accelMag - 9.81).abs();

    final gyroMag = _mag3(_gyroX, _gyroY, _gyroZ);
    final jerk = _computeJerk(accelDelta, now);

    final sample = SensorSample(
      x: _accelX,
      y: _accelY,
      z: _accelZ,
      gx: _gyroX,
      gy: _gyroY,
      gz: _gyroZ,
      timestamp: now,
      latitude: position?.latitude ?? 0.0,
      longitude: position?.longitude ?? 0.0,
      contextRisk: _contextRisk(now),
    );

    final assessment = _riskEngine.ingestSample(sample);

    // 🎯 HACKATHON-LEVEL: Performance monitoring
    _sampleCount++;
    if (assessment.score >= 70) _highRiskCount++;
    
    // Log stats every 100 samples (~15 seconds)
    if (_sampleCount % 100 == 0 && _startTime != null) {
      final elapsed = now.difference(_startTime!).inSeconds;
      final sampleRate = _sampleCount / elapsed;
      print('📊 Stats: $_sampleCount samples, ${sampleRate.toStringAsFixed(1)} Hz, $_highRiskCount high-risk');
    }

    _riskStreamController.add(RiskFrame(
      sample: sample,
      assessment: assessment,
      gyroMag: gyroMag,
      jerk: jerk,
    ));
  }

  double _mag3(double x, double y, double z) => math.sqrt(x * x + y * y + z * z);

  double _computeJerk(double accelDelta, DateTime now) {
    if (_prevAccelTs == null) {
      _prevAccelTs = now;
      _prevAccelDelta = accelDelta;
      return 0.0;
    }
    final dtMs = now.difference(_prevAccelTs!).inMilliseconds;
    if (dtMs <= 0) return 0.0;

    final dt = dtMs / 1000.0;
    final j = (accelDelta - _prevAccelDelta).abs() / dt;

    _prevAccelTs = now;
    _prevAccelDelta = accelDelta;
    return j;
  }

  double _contextRisk(DateTime now) {
    final hour = now.hour;
    // Keep context small; never let it be sole trigger.
    if (hour >= 22 || hour <= 5) return 0.65;
    return 0.45;
  }

  void _startLocationUpdates() {
    _updateLocation();
    _locationTimer = Timer.periodic(locationInterval, (_) => _updateLocation());
  }

  Future<void> _updateLocation() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) _lastPosition = last;

      final fresh = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 6),
      );
      _lastPosition = fresh;
    } catch (_) {
      // swallow (indoors / denied / timeouts). Don't crash safety app.
    }
  }

  /// Simulate high risk for testing
  void simulateHighRisk() {
    final now = DateTime.now();
    final position = _lastPosition;

    // 25 samples ~ 3.75 seconds at 150ms
    for (int i = 0; i < 25; i++) {
      final ts = now.add(Duration(milliseconds: i * sampleInterval.inMilliseconds));

      final sample = SensorSample(
        x: 14.0 + (i % 3) * 2.0,
        y: 12.0,
        z: 18.0,
        gx: 4.0 + (i % 4) * 1.2,
        gy: 4.5,
        gz: 5.5,
        timestamp: ts,
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        contextRisk: 0.8,
      );

      final assessment = _riskEngine.ingestSample(sample);
      final gyroMag = _mag3(sample.gx, sample.gy, sample.gz);
      final accelMag = _mag3(sample.x, sample.y, sample.z);
      final accelDelta = (accelMag - 9.81).abs();
      final j = _computeJerk(accelDelta, ts);

      _riskStreamController.add(RiskFrame(
        sample: sample,
        assessment: assessment,
        gyroMag: gyroMag,
        jerk: j,
      ));
    }
  }
}

/// A single "frame" emitted to UI + alert policy
class RiskFrame {
  RiskFrame({
    required this.sample,
    required this.assessment,
    required this.gyroMag,
    required this.jerk,
  });

  final SensorSample sample;
  final RiskAssessment assessment;
  final double gyroMag;
  final double jerk;
}
