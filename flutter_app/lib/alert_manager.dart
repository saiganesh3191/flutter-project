import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

/// Manages alert sending via SMS and backend logging
class AlertManager {
  final StorageService _storage = StorageService();
  final Telephony _telephony = Telephony.instance;
  
  // Backend configuration
  // For Android emulator, use: 'http://10.0.2.2:8000'
  // For real device, replace with your computer's IP
  static const String backendUrl = 'http://10.0.2.2:8000'; // Change this if using real device

  /// Send SMS alert with location
  Future<bool> sendAlert({
    required Position? position,
    required String reason,
    required String triggeredBy, // 'timer' or 'manual'
  }) async {
    try {
      final contactName = await _storage.getContactName();
      final contactPhone = await _storage.getContactPhone();

      if (contactPhone == null || contactPhone.isEmpty) {
        print('No contact phone available');
        return false;
      }

      // Build SMS message
      final message = _buildSmsMessage(contactName ?? 'User', position, reason);

      // Send SMS via device
      final smsSent = await _sendSms(contactPhone, message);

      // Log to backend (best effort, non-blocking)
      _logAlertToBackend(
        contactPhone: contactPhone,
        position: position,
        reason: reason,
        triggeredBy: triggeredBy,
      );

      return smsSent;
    } catch (e) {
      print('Alert sending error: $e');
      return false;
    }
  }

  String _buildSmsMessage(String userName, Position? position, String reason) {
    final buffer = StringBuffer();
    buffer.writeln('🚨 ALERT from $userName');
    buffer.writeln('Reason: $reason');
    
    if (position != null) {
      final mapsUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      buffer.writeln('Location: $mapsUrl');
    } else {
      buffer.writeln('Location: unavailable');
    }
    
    return buffer.toString();
  }

  Future<bool> _sendSms(String phone, String message) async {
    try {
      await _telephony.sendSms(
        to: phone,
        message: message,
      );
      return true;
    } catch (e) {
      print('SMS send error: $e');
      return false;
    }
  }

  Future<void> _logAlertToBackend({
    required String contactPhone,
    required Position? position,
    required String reason,
    required String triggeredBy,
  }) async {
    try {
      final deviceToken = await _storage.getDeviceToken();
      if (deviceToken == null) return;

      final response = await http.post(
        Uri.parse('$backendUrl/api/v1/alerts/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_token': deviceToken,
          'contact_phone': contactPhone,
          'lat': position?.latitude,
          'lng': position?.longitude,
          'message': reason,
          'triggered_by': triggeredBy,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 201) {
        print('Alert logged to backend');
      }
    } catch (e) {
      print('Backend logging failed (non-critical): $e');
    }
  }

  /// Register device with backend
  Future<String?> registerDevice() async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/v1/device/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'platform': 'android',
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['device_token'];
        await _storage.saveDeviceToken(token);
        return token;
      }
    } catch (e) {
      print('Device registration failed: $e');
    }
    return null;
  }

  /// Sync contact to backend
  Future<void> syncContact(String name, String phone) async {
    try {
      final deviceToken = await _storage.getDeviceToken();
      if (deviceToken == null) return;

      await http.post(
        Uri.parse('$backendUrl/api/v1/contacts/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'device_token': deviceToken,
          'name': name,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      print('Contact sync failed (non-critical): $e');
    }
  }
}
