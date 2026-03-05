# Testing Guide - AegisAI (No Backend)

## Quick Test Steps

### 1. First Time Setup

```bash
cd aegis_app
flutter clean
flutter pub get
flutter run
```

### 2. Admin Setup

1. **Login Screen**:
   - Select "Admin" role
   - Enter your phone number (e.g., 9876543210)
   - Click "Login"

2. **Onboarding Screen**:
   - Enter your phone number again (auto-filled from backend)
   - Add at least 1 contact (max 5):
     - Contact 1 (Priority 1) - Will receive alerts
     - Contact 2 (Priority 2) - Will receive alerts
     - Contact 3 (Priority 3) - Will receive alerts
     - Contact 4 & 5 - Backup contacts
   - Click "Save & Continue"

3. **Grant Permissions**:
   - Location: Allow
   - SMS: Allow
   - Activity Recognition: Allow

### 3. Test WhatsApp (Important!)

Before testing alerts, make sure your emergency contacts join the WhatsApp sandbox:

1. **Save Twilio number**: +1 415 523 8886
2. **Send WhatsApp message**: "join desk-whistle"
3. **Wait for confirmation**: "You are all set!"

### 4. Test Alert Sending

#### Method 1: Manual Test
1. Click "Test Alert" button
2. Wait 5 seconds (countdown)
3. Click "Send Alert Now" or wait for auto-send
4. Check:
   - SMS received by contacts
   - WhatsApp message received by contacts
   - Alert sent screen shows success

#### Method 2: Auto-Trigger Test
1. Click "Start" to begin monitoring
2. Shake your phone vigorously for 2-3 seconds
3. Watch the risk meter increase
4. When score reaches 70+, alert popup appears automatically
5. Wait 5 seconds or click "Send Alert Now"
6. Check SMS + WhatsApp received

### 5. Test Background Monitoring

1. Start monitoring
2. Press home button (app goes to background)
3. Check notification: "AegisAI Monitoring Active"
4. Shake phone vigorously
5. Alert should trigger even when app is closed
6. Check SMS + WhatsApp received

### 6. Test Contact Login

1. Logout from admin account
2. Login as "Contact" with one of the emergency contact numbers
3. Should see simple receiver interface
4. Trigger alert from admin device
5. Contact should receive SMS + WhatsApp

## Expected Behavior

### Risk Meter
- **0-19**: LOW (Green) - "You're Safe"
- **20-39**: MODERATE (Yellow) - "Stay Alert"
- **40-69**: HIGH (Orange) - "High Risk!"
- **70-100**: SEVERE (Red) - "High Risk!" + Auto-trigger

### Alert Popup
- Appears automatically when score >= 70
- 5-second countdown
- Options: "I Am Safe" or "Send Alert Now"
- Auto-sends after 5 seconds

### SMS Message
```
 ALERT from [Your Phone]. Location: [Google Maps Link]
```

### WhatsApp Message
```
 *EMERGENCY ALERT*

Alert from: *[Your Phone]*

 High risk situation detected!

 Location: [Google Maps Link]

Please check on them immediately!
```

## Troubleshooting

### Alert not triggering?
- Check if monitoring is started (green "Stop" button)
- Shake phone more vigorously
- Check logs for "Risk state changed to HIGH"
- Score must reach 70+ to trigger

### SMS not received?
- Check SMS permission granted
- Check phone number format (+91XXXXXXXXXX)
- Check MSG91 API logs
- Verify 100 free SMS not exhausted

### WhatsApp not received?
- **Most common**: Recipient didn't join sandbox
- Send "join desk-whistle" to +14155238886
- Wait for confirmation message
- Try again

### App crashes?
- Run `flutter clean`
- Delete app from device
- Reinstall: `flutter run`

### Risk score not increasing?
- Shake phone harder
- Check sensor logs in console
- Verify accelerometer working
- Try "Test Alert" button instead

## Data Verification

### Check Local Database
All data stored in Hive boxes:
- Contacts: `contacts` box
- Alerts: `alerts` box
- Settings: `settings` box

### Check Logs
Look for these in console:
- ` Local database initialized`
- ` Saved X contacts locally`
- ` Risk Event: ...`
- ` Risk Update: score=X`
- ` Sending alert via SMS + WhatsApp...`
- ` SMS sent to X/Y contacts`
- ` WhatsApp sent to X/Y contacts`

## Performance Tips

### Battery Optimization
- Background monitoring uses foreground service
- Efficient sensor sampling (150ms intervals)
- Location updates every 20 seconds
- Minimal battery impact

### Network Usage
- SMS: ~1KB per message
- WhatsApp: ~2KB per message
- Total: ~3KB per alert
- Very low data usage

## Production Checklist

Before deploying to real users:

- [ ] Test with real phone numbers
- [ ] Verify SMS delivery
- [ ] Verify WhatsApp delivery (after sandbox join)
- [ ] Test background monitoring
- [ ] Test auto-trigger
- [ ] Test manual trigger
- [ ] Test logout/login
- [ ] Test app uninstall (data deleted)
- [ ] Test permissions
- [ ] Test location accuracy
- [ ] Check battery usage
- [ ] Verify cooldown works (10s for testing)

## Known Issues

1. **WhatsApp Sandbox**: Recipients must join first
2. **Telephony package**: Discontinued but still works
3. **Location permission**: Must be "Always" for background
4. **Battery optimization**: Disable for app on some devices

## Next Steps

1. Test thoroughly with real contacts
2. Consider upgrading to Twilio WhatsApp Business API
3. Adjust cooldown to 60s for production
4. Add more contacts if needed
5. Customize alert messages
6. Add more risk detection rules
