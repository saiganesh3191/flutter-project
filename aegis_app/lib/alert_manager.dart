import 'package:geolocator/geolocator.dart';
import 'local_database.dart';
import 'sms_service.dart';

/// Alert manager - handles sending alerts WITHOUT backend server
/// All data stored locally, SMS sent directly from app
class AlertManager {
  /// Send alert to top 3 contacts
  Future<bool> sendAlert({
    Position? position,
    String reason = 'High risk detected',
    String triggeredBy = 'auto',
  }) async {
    try {
      print('🚨 Sending alert via SMS + WhatsApp...');

      // Get top 3 contacts from local database
      final contacts = LocalDatabase.getTopContacts();
      
      if (contacts.isEmpty) {
        print('❌ No contacts found');
        return false;
      }

      // Get user phone
      final userPhone = LocalDatabase.getUserPhone() ?? 'User';

      // Extract phone numbers
      final phoneNumbers = contacts.map((c) => c['phone'] as String).toList();

      // Send SMS + WhatsApp to all contacts
      final success = await SmsService.sendAlertSms(
        phoneNumbers: phoneNumbers,
        userName: userPhone,
        position: position,
      );

      // Save alert to local database
      await LocalDatabase.saveAlert({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'reason': reason,
        'triggered_by': triggeredBy,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'contacts_notified': phoneNumbers.length,
        'success': success,
      });

      if (success) {
        print('✅ Alert sent successfully to ${phoneNumbers.length} contacts (SMS + WhatsApp)');
      } else {
        print('⚠️ Alert partially sent');
      }

      return success;
    } catch (e) {
      print('❌ Alert error: $e');
      return false;
    }
  }

  /// Get contacts from local database
  Future<List<Map<String, dynamic>>?> getContactsFromBackend() async {
    return LocalDatabase.getContacts();
  }

  /// Get device info (for compatibility)
  Future<Map<String, dynamic>?> getDeviceInfoFromBackend() async {
    return {
      'phone_number': LocalDatabase.getUserPhone(),
      'device_id': LocalDatabase.getDeviceId(),
    };
  }
}
