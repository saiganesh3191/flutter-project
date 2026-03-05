import 'package:shared_preferences/shared_preferences.dart';

/// Storage service for persisting app data locally
class StorageService {
  static const String _keyOnboarded = 'onboarded';
  static const String _keyContactName = 'contact_name';
  static const String _keyContactPhone = 'contact_phone';
  static const String _keyDeviceToken = 'device_token';

  /// Check if user has completed onboarding
  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarded) ?? false;
  }

  /// Save trusted contact information
  Future<void> saveContact(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyContactName, name);
    await prefs.setString(_keyContactPhone, phone);
    await prefs.setBool(_keyOnboarded, true);
  }

  /// Get trusted contact name
  Future<String?> getContactName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyContactName);
  }

  /// Get trusted contact phone
  Future<String?> getContactPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyContactPhone);
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

  /// Clear all data (for testing)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
