# WhatsApp Alert Setup Guide

## Overview
The app now sends alerts via both SMS and WhatsApp for maximum reliability. WhatsApp messages are sent using Twilio's WhatsApp API.

## Current Setup (Sandbox Mode)

### Twilio WhatsApp Sandbox
- **Account SID**: `AC0ac44ad4accdefdbc4d0d8355c60be20`
- **Auth Token**: `2b4bb1b3063d38e47746a1c3ccd14732`
- **WhatsApp Number**: `+14155238886`
- **Join Code**: `join desk-whistle`

### How Recipients Join the Sandbox

For emergency contacts to receive WhatsApp alerts, they must:

1. **Save the Twilio number** in their phone: `+1 415 523 8886`

2. **Send a WhatsApp message** to that number with the text:
   ```
   join desk-whistle
   ```

3. **Wait for confirmation** - They'll receive a message like:
   ```
   Twilio Sandbox:  You are all set! The sandbox can now send/receive messages from this number.
   ```

4. **Done!** They can now receive emergency alerts via WhatsApp

### Important Notes

- **Sandbox Limitations**:
  - Each recipient must join the sandbox first
  - Sandbox is free but for testing only
  - Messages expire after 24 hours of inactivity (recipients need to rejoin)

- **For Production**:
  - Apply for Twilio WhatsApp Business API
  - Get your own WhatsApp Business number
  - No need for recipients to "join" anything
  - More reliable and professional

## Message Format

When an alert is triggered, contacts receive:

```
 *EMERGENCY ALERT*

Alert from: *[User's Phone Number]*

 High risk situation detected!

 Location: https://maps.google.com/?q=lat,lng

Please check on them immediately!
```

## Testing WhatsApp

1. **Add yourself as a contact** in the app
2. **Join the sandbox** by sending "join desk-whistle" to +14155238886
3. **Trigger a test alert** in the app
4. **Check WhatsApp** - You should receive the alert message

## Troubleshooting

### WhatsApp not received?

1. **Check if recipient joined sandbox**:
   - They must send "join desk-whistle" first
   - Check for confirmation message

2. **Check phone number format**:
   - App automatically adds +91 for Indian numbers
   - Format: +91XXXXXXXXXX

3. **Check Twilio logs**:
   - Login to Twilio console
   - Check message logs for errors

4. **Sandbox expired?**:
   - After 24 hours of inactivity, recipients need to rejoin
   - Send "join desk-whistle" again

### SMS works but WhatsApp doesn't?

- This is normal if recipient hasn't joined sandbox
- SMS is the primary alert method
- WhatsApp is a backup/additional channel

## Production Setup (Optional)

To use WhatsApp in production without sandbox:

1. **Apply for Twilio WhatsApp Business API**:
   - Go to Twilio Console → Messaging → WhatsApp
   - Click "Request Access"
   - Fill business details

2. **Get approved** (takes 1-2 weeks)

3. **Update credentials** in `sms_service.dart`:
   ```dart
   static const String twilioWhatsAppNumber = 'whatsapp:+YOUR_BUSINESS_NUMBER';
   ```

4. **No more "join" required** - Recipients receive messages directly

## Cost

- **Sandbox**: Free (for testing)
- **Production**: ~$0.005 per message (very cheap)
- **SMS (MSG91)**: 100 free/day, then ~₹0.20 per SMS

## Security

- Credentials are hardcoded in the app (for simplicity)
- For production, consider:
  - Environment variables
  - Secure key storage
  - Backend API (optional)

## Support

If you need help:
1. Check Twilio console for message logs
2. Verify recipient joined sandbox
3. Test with your own number first
4. Check app logs for errors
