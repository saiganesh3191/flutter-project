import 'package:hive_flutter/hive_flutter.dart';

/// Local database service using Hive (like MongoDB but local)
/// All data stored on device, deleted when app is uninstalled
class LocalDatabase {
  static const String _contactsBox = 'contacts';
  static const String _alertsBox = 'alerts';
  static const String _settingsBox = 'settings';

  /// Initialize Hive database
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Open boxes (like MongoDB collections)
    await Hive.openBox(_contactsBox);
    await Hive.openBox(_alertsBox);
    await Hive.openBox(_settingsBox);
    
    print('✅ Local database initialized');
  }

  // ==================== CONTACTS ====================
  
  /// Save contacts (max 5)
  static Future<void> saveContacts(List<Map<String, dynamic>> contacts) async {
    final box = Hive.box(_contactsBox);
    await box.clear(); // Clear old contacts
    
    for (int i = 0; i < contacts.length && i < 5; i++) {
      await box.put('contact_$i', contacts[i]);
    }
    
    print('✅ Saved ${contacts.length} contacts locally');
  }

  /// Get all contacts
  static List<Map<String, dynamic>> getContacts() {
    final box = Hive.box(_contactsBox);
    final contacts = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 5; i++) {
      final contact = box.get('contact_$i');
      if (contact != null) {
        contacts.add(Map<String, dynamic>.from(contact));
      }
    }
    
    // Sort by priority
    contacts.sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));
    
    return contacts;
  }

  /// Get top 3 priority contacts
  static List<Map<String, dynamic>> getTopContacts() {
    final contacts = getContacts();
    return contacts.take(3).toList();
  }

  /// Check if phone number exists as contact
  static bool isContact(String phoneNumber) {
    final contacts = getContacts();
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    final last10 = cleanPhone.length >= 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;
    
    for (final contact in contacts) {
      final contactPhone = (contact['phone'] as String).replaceAll(RegExp(r'[^\d]'), '');
      final contactLast10 = contactPhone.length >= 10 ? contactPhone.substring(contactPhone.length - 10) : contactPhone;
      
      if (last10 == contactLast10) {
        return true;
      }
    }
    
    return false;
  }

  // ==================== ALERTS ====================
  
  /// Save alert log
  static Future<void> saveAlert(Map<String, dynamic> alert) async {
    final box = Hive.box(_alertsBox);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await box.put('alert_$timestamp', alert);
    
    print('✅ Alert saved locally');
  }

  /// Get all alerts
  static List<Map<String, dynamic>> getAlerts() {
    final box = Hive.box(_alertsBox);
    final alerts = <Map<String, dynamic>>[];
    
    for (final key in box.keys) {
      final alert = box.get(key);
      if (alert != null) {
        alerts.add(Map<String, dynamic>.from(alert));
      }
    }
    
    // Sort by timestamp (newest first)
    alerts.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
    
    return alerts;
  }

  // ==================== SETTINGS ====================
  
  /// Save user phone number
  static Future<void> saveUserPhone(String phone) async {
    final box = Hive.box(_settingsBox);
    await box.put('user_phone', phone);
  }

  /// Get user phone number
  static String? getUserPhone() {
    final box = Hive.box(_settingsBox);
    return box.get('user_phone');
  }

  /// Save user role (admin or contact)
  static Future<void> saveUserRole(String role) async {
    final box = Hive.box(_settingsBox);
    await box.put('user_role', role);
  }

  /// Get user role
  static String? getUserRole() {
    final box = Hive.box(_settingsBox);
    return box.get('user_role');
  }

  /// Save device ID
  static Future<void> saveDeviceId(String deviceId) async {
    final box = Hive.box(_settingsBox);
    await box.put('device_id', deviceId);
  }

  /// Get device ID
  static String? getDeviceId() {
    final box = Hive.box(_settingsBox);
    return box.get('device_id');
  }

  /// Save FCM token
  static Future<void> saveFcmToken(String token) async {
    final box = Hive.box(_settingsBox);
    await box.put('fcm_token', token);
  }

  /// Get FCM token
  static String? getFcmToken() {
    final box = Hive.box(_settingsBox);
    return box.get('fcm_token');
  }

  // ==================== CLEAR ALL ====================
  
  /// Clear all data (logout)
  static Future<void> clearAll() async {
    await Hive.box(_contactsBox).clear();
    await Hive.box(_alertsBox).clear();
    await Hive.box(_settingsBox).clear();
    
    print('✅ All local data cleared');
  }
}
