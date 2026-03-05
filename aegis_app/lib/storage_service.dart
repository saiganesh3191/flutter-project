import 'package:shared_preferences/shared_preferences.dart';

/// Storage service for persisting app data locally
class StorageService {
  static const String _keyOnboarded = 'onboarded';
  static const String _keyContactName = 'contact_name';
  static const String _keyContactPhone = 'contact_phone';
  static const String _keyDeviceToken = 'device_token';
  static const String _keyUserRole = 'user_role'; // 'admin' or 'client'
  static const String _keyUserPhone = 'user_phone';

  /// Check if user has completed onboarding
  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }

  /// Save trusted contact information (backend only)
  Future<bool> saveContact(String name, String phone) async {
    // Only save device token locally, contact goes to backend
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarded, true);
    return true;
  }

  /// Get trusted contact name from backend (not local)
  Future<String?> getContactName() async {
    // This will be fetched from backend in alert_manager
    return null;
  }

  /// Get trusted contact phone from backend (not local)
  Future<String?> getContactPhone() async {
    // This will be fetched from backend in alert_manager
    return null;
  }

  /// Save device token from backend
  Future<void> saveDeviceToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceToken, token);
  }

  /// Get device token
  Future<String?> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDeviceToken);
  }

  /// Save user role (admin or client)
  Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRole, role);
    await prefs.setBool(_keyOnboarded, true);
  }

  /// Get user role
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  /// Save user phone
  Future<void> saveUserPhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserPhone, phone);
  }

  /// Get user phone
  Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserPhone);
  }

  /// Clear all data (for testing)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
