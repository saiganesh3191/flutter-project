import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Background monitoring service that runs even when app is closed
class BackgroundMonitoringService {
  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'aegis_monitoring',
        channelName: 'AegisAI Monitoring',
        channelDescription: 'Background safety monitoring',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000, // Check every 5 seconds
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<bool> startService({
    required String deviceToken,
    required String backendUrl,
  }) async {
    if (await FlutterForegroundTask.isRunningService) {
      return true;
    }

    return await FlutterForegroundTask.startService(
      notificationTitle: 'AegisAI Monitoring Active',
      notificationText: 'Protecting you in the background',
      callback: startCallback,
    );
  }

  static Future<bool> stopService() async {
    return await FlutterForegroundTask.stopService();
  }

  static Future<bool> isRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MonitoringTaskHandler());
}

class MonitoringTaskHandler extends TaskHandler {
  SendPort? _sendPort;
  int _riskScore = 0;
  DateTime? _lastAlertTime;
  
  // Sensor data buffers
  final List<double> _accelMagnitudes = [];
  final List<double> _gyroMagnitudes = [];
  
  // Thresholds
  static const double accelThreshold = 15.0; // High acceleration
  static const int spikeCount = 3; // Need 3 spikes
  static const Duration spikeWindow = Duration(seconds: 4);
  static const Duration alertCooldown = Duration(minutes: 2);

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;
    print('🟢 Background monitoring started');
    
    // Listen to sensors
    _startSensorMonitoring();
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // Update notification
    FlutterForegroundTask.updateService(
      notificationTitle: 'AegisAI Monitoring',
      notificationText: 'Risk Score: $_riskScore | Status: ${_getStatus()}',
    );
    
    // Check for high risk
    if (_riskScore >= 70 && _canSendAlert()) {
      await _sendAlert();
    }
    
    // Decay score
    if (_riskScore > 0) {
      _riskScore = (_riskScore - 2).clamp(0, 100);
    }
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    print('🔴 Background monitoring stopped');
  }

  void _startSensorMonitoring() {
    // Monitor accelerometer
    accelerometerEvents.listen((event) {
      final magnitude = _calculateMagnitude(event.x, event.y, event.z);
      
      if (magnitude > accelThreshold) {
        _accelMagnitudes.add(magnitude);
        _cleanOldSpikes();
        
        if (_accelMagnitudes.length >= spikeCount) {
          _riskScore = (_riskScore + 25).clamp(0, 100);
          _accelMagnitudes.clear();
          print('⚠️ High risk detected! Score: $_riskScore');
        }
      }
    });

    // Monitor gyroscope
    gyroscopeEvents.listen((event) {
      final magnitude = _calculateMagnitude(event.x, event.y, event.z);
      
      if (magnitude > 4.0) {
        _gyroMagnitudes.add(magnitude);
        
        if (_gyroMagnitudes.length >= 2) {
          _riskScore = (_riskScore + 15).clamp(0, 100);
          _gyroMagnitudes.clear();
        }
      }
    });
  }

  double _calculateMagnitude(double x, double y, double z) {
    return (x * x + y * y + z * z).abs();
  }

  void _cleanOldSpikes() {
    // Keep only recent spikes (simple implementation)
    if (_accelMagnitudes.length > 10) {
      _accelMagnitudes.removeAt(0);
    }
    if (_gyroMagnitudes.length > 10) {
      _gyroMagnitudes.removeAt(0);
    }
  }

  String _getStatus() {
    if (_riskScore >= 70) return 'HIGH RISK';
    if (_riskScore >= 40) return 'Medium';
    return 'Safe';
  }

  bool _canSendAlert() {
    if (_lastAlertTime == null) return true;
    return DateTime.now().difference(_lastAlertTime!) > alertCooldown;
  }

  Future<void> _sendAlert() async {
    _lastAlertTime = DateTime.now();
    
    try {
      // Get location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        print('Location error: $e');
      }

      // Get device token from shared preferences
      final deviceToken = await _getDeviceToken();
      if (deviceToken == null) {
        print('No device token found');
        return;
      }

      // Send alert to backend
      const backendUrl = 'http://192.168.0.122:8000';
      final response = await http.post(
        Uri.parse('$backendUrl/api/v1/alerts/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_token': deviceToken,
          'lat': position?.latitude,
          'lng': position?.longitude,
          'message': 'High risk detected (background)',
          'triggered_by': 'background',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        print('✅ Background alert sent successfully');
        
        // Show local notification
        FlutterForegroundTask.updateService(
          notificationTitle: '🚨 ALERT SENT',
          notificationText: 'Emergency contacts notified!',
        );
      }
    } catch (e) {
      print('❌ Background alert failed: $e');
    }
  }

  Future<String?> _getDeviceToken() async {
    // This is a simplified version - in production, use proper storage
    // For now, we'll need to pass it when starting the service
    return null; // TODO: Implement proper token storage
  }
}
