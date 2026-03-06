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
  // Get your credentials from: https://www.twilio.com/console
  // Sign up at: https://www.twilio.com/try-twilio
  static const String twilioAccountSid = 'AC0ac44ad4accdefdbc4d0d8355c60be20';
  static const String twilioAuthToken = '45502d301b4ea7bc25695f50d7f703c0';
  static const String twilioWhatsAppNumber = 'whatsapp:+14155238886';
  
  // Set to false to disable WhatsApp if you don't have valid credentials
  static const bool enableWhatsApp = true;

  /// Send SMS + WhatsApp to multiple contacts
  static Future<bool> sendAlertSms({
    required List<String> phoneNumbers,
    required List<String> contactNames,
    required String userName,
    required String userPhone,
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

      for (int i = 0; i < phoneNumbers.length; i++) {
        final phone = phoneNumbers[i];
        final contactName = i < contactNames.length ? contactNames[i] : 'Contact';
        
        // Send SMS (always)
        final smsSuccess = await _sendSingleSms(
          phone: phone,
          contactName: contactName,
          userName: userName,
          userPhone: userPhone,
          locationLink: locationLink,
        );
        if (smsSuccess) smsSuccessCount++;

        // Send WhatsApp (only if enabled)
        if (enableWhatsApp) {
          final whatsappSuccess = await _sendWhatsApp(
            phone: phone,
            contactName: contactName,
            userName: userName,
            userPhone: userPhone,
            locationLink: locationLink,
          );
          if (whatsappSuccess) whatsappSuccessCount++;
        }
      }

      print('✅ SMS sent to $smsSuccessCount/${phoneNumbers.length} contacts');
      if (enableWhatsApp) {
        print('✅ WhatsApp sent to $whatsappSuccessCount/${phoneNumbers.length} contacts');
      } else {
        print('ℹ️ WhatsApp disabled - update Twilio credentials to enable');
      }

      return smsSuccessCount > 0 || whatsappSuccessCount > 0;
    } catch (e) {
      print('❌ Alert error: $e');
      return false;
    }
  }

  /// Send SMS to single contact using MSG91 API
  static Future<bool> _sendSingleSms({
    required String phone,
    required String contactName,
    required String userName,
    required String userPhone,
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
                  'var1': contactName,
                  'var2': userName,
                  'var3': userPhone,
                  'var4': locationLink,
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
    required String contactName,
    required String userName,
    required String userPhone,
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

      // Build message with contact name
      final message = '🚨 *EMERGENCY ALERT*\n\n'
          'Hi $contactName,\n\n'
          'Alert from: *$userName* ($userPhone)\n\n'
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
