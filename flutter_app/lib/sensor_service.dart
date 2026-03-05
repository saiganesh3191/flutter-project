import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'risk_engine.dart';

/// Service for managing sensors and risk evaluation
class SensorService {
  final RiskEngine _riskEngine = RiskEngine();
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _locationTimer;
  Timer? _throttleTimer;
  
  Position? _lastPosition;
  bool _isRunning = false;
  
  // Throttle sensor updates to reduce battery drain
  static const Duration throttleDuration = Duration(milliseconds: 500);
  static const Duration locationInterval = Duration(seconds: 20);

  final _riskStreamController = StreamController<RiskResult>.broadcast();
  Stream<RiskResult> get riskStream => _riskStreamController.stream;

  RiskEngine get riskEngine => _riskEngine;
  Position? get lastPosition => _lastPosition;

  /// Start monitoring sensors
  Future<void> start() async {
    if (_isRunning) return;
    
    _isRunning = true;
    
    // Start accelerometer with throttling
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      if (_throttleTimer == null || !_throttleTimer!.isActive) {
        _processAccelerometer(event);
        _throttleTimer = Timer(throttleDuration, () {});
      }
    }, onError: (error) {
      print('Accelerometer error: $error');
    });

    // Start periodic location updates
    _startLocationUpdates();
  }

  /// Stop all monitoring
  void stop() {
    _isRunning = false;
    
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    
    _locationTimer?.cancel();
    _locationTimer = null;
    
    _throttleTimer?.cancel();
    _throttleTimer = null;
  }

  void _processAccelerometer(AccelerometerEvent event) {
    if (!_isRunning) return;
    
    final result = _riskEngine.processAccelerometer(event.x, event.y, event.z);
    _riskStreamController.add(result);
  }

  void _startLocationUpdates() {
    _updateLocation(); // Get initial location
    
    _locationTimer = Timer.periodic(locationInterval, (_) {
      _updateLocation();
    });
  }

  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastPosition = position;
    } catch (e) {
      print('Location error: $e');
    }
  }

  /// Simulate high risk for testing
  void simulateHighRisk() {
    final result = _riskEngine.simulateHighRisk();
    _riskStreamController.add(result);
  }

  bool get isRunning => _isRunning;

  void dispose() {
    stop();
    _riskStreamController.close();
  }
}
