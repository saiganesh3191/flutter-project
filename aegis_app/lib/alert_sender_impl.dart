import 'package:geolocator/geolocator.dart';
import 'alert_orchestrator_night.dart';
import 'alert_manager.dart';

/// Production AlertSender that uses existing SMS + WhatsApp services
class AegisAlertSender implements AlertSender {
  final AlertManager _alertManager = AlertManager();

  @override
  Future<void> sendEmergencyAlert({
    required DateTime at,
    required double lat,
    required double lon,
    required int score,
    required List<String> reasons,
  }) async {
    print('🚨 EMERGENCY ALERT TRIGGERED!');
    print('   Time: $at');
    print('   Score: $score');
    print('   Location: $lat, $lon');
    print('   Reasons: ${reasons.join(", ")}');

    // Create Position object for alert manager
    Position? position;
    if (lat != 0.0 && lon != 0.0) {
      position = Position(
        latitude: lat,
        longitude: lon,
        timestamp: at,
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    // Send alert via SMS + WhatsApp to top 3 contacts
    final success = await _alertManager.sendAlert(
      position: position,
      reason: 'High risk detected (score: $score)',
      triggeredBy: 'auto',
    );

    if (success) {
      print('✅ Emergency alert sent successfully');
    } else {
      print('❌ Failed to send emergency alert');
    }
  }
}
