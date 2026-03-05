import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

/// SMS & WhatsApp service for sending alerts directly from the app
class SmsService {
  // MSG91 credentials (for reliable SMS delivery)
  static const String msg91AuthKey = '497258ACavnGkGmYQ569a3cb4fP1';
  static const String msg91TemplateId = '69a3e0c2de901ea1a3077254';
  static const String msg91SenderId = 'AEGSAI';

  // Twilio WhatsApp credentials
  static const String twilioAccountSid = 'ACff8549e7f6e392ac066408332cad0ef8';
  static const String twilioAuthToken = '1764d39571b650dc23a7a1b1c81b05af';
  static const String twilioWhatsAppNumber = 'whatsapp:+14155238886';

  /// Send SMS + WhatsApp to multiple contacts
  static Future<bool> sendAlertSms({
    required List<String> phoneNumbers,
    required String userName,
    Position? position,
  }) async {
    try {
      // Build Google Maps link
      String locationLink = 'Location unavailable';
      if (position != null) {
        locationLink =
            'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      }

      // Send to each contact (both SMS and WhatsApp)
      int smsSuccessCount = 0;
      int whatsappSuccessCount = 0;

      for (final phone in phoneNumbers) {
        // Send SMS
        final smsSuccess = await _sendSingleSms(
          phone: phone,
          userName: userName,
          locationLink: locationLink,
        );
        if (smsSuccess) smsSuccessCount++;

        // Send WhatsApp
        final whatsappSuccess = await _sendWhatsApp(
          phone: phone,
          userName: userName,
          locationLink: locationLink,
        );
        if (whatsappSuccess) whatsappSuccessCount++;
      }

      print('✅ SMS sent to $smsSuccessCount/${phoneNumbers.length} contacts');
      print(
          '✅ WhatsApp sent to $whatsappSuccessCount/${phoneNumbers.length} contacts');

      return smsSuccessCount > 0 || whatsappSuccessCount > 0;
    } catch (e) {
      print('❌ Alert error: $e');
      return false;
    }
  }

  /// Send SMS to single contact using MSG91 API
  static Future<bool> _sendSingleSms({
    required String phone,
    required String userName,
    required String locationLink,
  }) async {
    try {
      // Clean phone number
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      // Add country code if not present
      String finalPhone = cleanPhone;
      if (!cleanPhone.startsWith('+')) {
        if (cleanPhone.startsWith('91')) {
          finalPhone = '+$cleanPhone';
        } else {
          finalPhone = '+91$cleanPhone';
        }
      }

      // MSG91 API endpoint (Route 4 - Transactional)
      final url = Uri.parse('https://control.msg91.com/api/v5/flow/');

      final response = await http
          .post(
            url,
            headers: {
              'authkey': msg91AuthKey,
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'template_id': msg91TemplateId,
              'short_url': '0',
              'recipients': [
                {
                  'mobiles': finalPhone,
                  'var1': userName,
                  'var2': locationLink,
                }
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ SMS sent to $phone');
        return true;
      } else {
        print(
            '❌ SMS failed for $phone: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ SMS error for $phone: $e');
      return false;
    }
  }

  /// WhatsApp message using Twilio API
  static Future<bool> _sendWhatsApp({
    required String phone,
    required String userName,
    required String locationLink,
  }) async {
    try {
      // Clean phone number
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

      // Add country code if not present
      String finalPhone = cleanPhone;
      if (!cleanPhone.startsWith('+')) {
        if (cleanPhone.startsWith('91')) {
          finalPhone = '+$cleanPhone';
        } else {
          finalPhone = '+91$cleanPhone';
        }
      }

      // WhatsApp number format
      final whatsappTo = 'whatsapp:$finalPhone';

      // Build message
      final message = '🚨 *EMERGENCY ALERT*\n\n'
          'Alert from: *$userName*\n\n'
          '⚠️ High risk situation detected!\n\n'
          '📍 Location: $locationLink\n\n'
          'Please check on them immediately!';

      // Twilio API endpoint
      final url = Uri.parse(
        'https://api.twilio.com/2010-04-01/Accounts/$twilioAccountSid/Messages.json',
      );

      // Basic auth
      final auth =
          base64Encode(utf8.encode('$twilioAccountSid:$twilioAuthToken'));

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $auth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': twilioWhatsAppNumber,
          'To': whatsappTo,
          'Body': message,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        print('✅ WhatsApp sent to $phone');
        return true;
      } else {
        print(
            '❌ WhatsApp failed for $phone: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ WhatsApp error for $phone: $e');
      return false;
    }
  }
}
