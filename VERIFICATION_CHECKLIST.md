# AegisAI Verification Checklist

Use this checklist to verify the complete system is working correctly.

## Pre-Flight Checks

### Backend Setup
- [ ] Python 3.9+ installed
- [ ] Virtual environment created and activated
- [ ] All requirements installed (`pip install -r requirements.txt`)
- [ ] `.env` file created from `.env.example`
- [ ] Database migrations run (`python manage.py migrate`)
- [ ] Backend server running on port 8000
- [ ] Admin panel accessible at `http://localhost:8000/admin/`

### Flutter Setup
- [ ] Flutter SDK 3.0+ installed
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Backend URL configured in `alert_manager.dart`
- [ ] Real Android device connected (not emulator)
- [ ] Device has SIM card installed
- [ ] USB debugging enabled on device
- [ ] Device detected by `flutter devices`

---

## Functional Testing

### 1. Onboarding Flow
- [ ] App opens to "AegisAI – Setup" screen
- [ ] Can enter trusted contact name
- [ ] Can enter trusted contact phone number
- [ ] "Save & Continue" button works
- [ ] Location permission requested
- [ ] SMS permission requested
- [ ] Activity Recognition permission requested
- [ ] All permissions granted
- [ ] Navigates to Home screen after permissions
- [ ] If permission denied, shows: "Permissions required for monitoring."

### 2. Home Screen - Initial State
- [ ] Title shows "AegisAI – Monitoring Dashboard"
- [ ] Monitoring toggle shows "Monitoring: OFF"
- [ ] Risk meter shows 0
- [ ] Risk meter is green
- [ ] Status shows "Safe"
- [ ] No reasons displayed (score is 0)
- [ ] "Test High Risk" button visible

### 3. Monitoring Toggle
- [ ] Can toggle to "Monitoring: ON"
- [ ] Risk meter starts updating
- [ ] Can toggle back to "Monitoring: OFF"
- [ ] Risk meter freezes when OFF
- [ ] Toggle state persists correctly

### 4. Risk Meter Behavior (Monitoring ON)
- [ ] Progress bar updates in real-time
- [ ] Score displays as number (0-100)
- [ ] Color changes: Green (0-39), Yellow (40-69), Red (70+)
- [ ] Status text updates: Safe, Medium Risk, High Risk
- [ ] Reasons appear when score > 0
- [ ] Reasons are readable and short

### 5. Test High Risk Button
- [ ] Button clickable when monitoring is ON
- [ ] Shows message if monitoring is OFF
- [ ] ALWAYS triggers confirmation popup
- [ ] Popup appears immediately
- [ ] No delay or randomness

### 6. Confirmation Popup
- [ ] Shows " High Risk Detected" title
- [ ] Warning icon displayed
- [ ] Countdown starts at 5
- [ ] Countdown decrements: 5...4...3...2...1
- [ ] "I Am Safe" button (green) visible
- [ ] "Send Alert Now" button (red) visible
- [ ] Cannot dismiss by tapping outside

### 7. "I Am Safe" Path
- [ ] Tap "I Am Safe" button
- [ ] Popup closes immediately
- [ ] Returns to Home screen
- [ ] Risk score resets to 0
- [ ] Monitoring remains ON
- [ ] Cooldown active (check reasons)
- [ ] No SMS sent

### 8. "Send Alert Now" Path
- [ ] Tap "Send Alert Now" button
- [ ] Popup closes
- [ ] Navigates to "Alert Sent" screen
- [ ] Shows "Alert Sent to: [Name]"
- [ ] Shows "Location Shared Successfully"
- [ ] SMS sent to trusted contact
- [ ] "Return to Dashboard" button visible

### 9. Timer Auto-Send Path
- [ ] Trigger popup (Test High Risk)
- [ ] Wait without clicking buttons
- [ ] Countdown reaches 0
- [ ] Popup closes automatically
- [ ] Navigates to "Alert Sent" screen
- [ ] SMS sent automatically

### 10. Alert Sent Screen
- [ ] Contact name displayed correctly
- [ ] Success message shown
- [ ] "Return to Dashboard" button works
- [ ] Returns to Home screen
- [ ] Monitoring still ON

### 11. SMS Verification
- [ ] SMS received on trusted contact's phone
- [ ] Message includes alert text
- [ ] Message includes Google Maps link
- [ ] Link format: `https://www.google.com/maps?q=lat,lng`
- [ ] Link opens in maps app
- [ ] Location is accurate

### 12. Backend Integration
- [ ] Open `http://localhost:8000/admin/`
- [ ] Login with admin credentials
- [ ] Check Devices: 1 device registered
- [ ] Device has valid token
- [ ] Check Trusted Contacts: Contact saved
- [ ] Contact name and phone correct
- [ ] Check Alerts: Alert logged
- [ ] Alert has location coordinates
- [ ] Alert shows triggered_by (timer/manual)

---

## Edge Cases & Error Handling

### Permission Handling
- [ ] Deny location permission → app shows warning
- [ ] Deny SMS permission → app shows warning
- [ ] Grant permissions later → app works correctly
- [ ] Revoke permissions → app handles gracefully

### Network Issues
- [ ] Disable WiFi/data → app still works locally
- [ ] SMS still sends without internet
- [ ] Backend sync happens when online again
- [ ] No crashes or freezes

### Background Behavior
- [ ] Minimize app → monitoring continues
- [ ] Lock screen → monitoring continues
- [ ] Foreground service notification visible
- [ ] Return to app → state preserved
- [ ] Force stop → monitoring stops cleanly

### Multiple Alerts
- [ ] Send first alert
- [ ] Wait 60 seconds (cooldown)
- [ ] Trigger second alert
- [ ] Both alerts work correctly
- [ ] No spam or duplicate alerts

### Risk Engine Logic
- [ ] Single spike doesn't trigger high risk
- [ ] Multiple spikes increase score
- [ ] Score decays over time
- [ ] Cooldown prevents immediate re-trigger
- [ ] Night time increases risk (after 10 PM)

---

## Performance Testing

### Battery Usage
- [ ] Monitoring for 10 minutes
- [ ] Battery drain is moderate
- [ ] No excessive heating
- [ ] App doesn't kill battery

### Memory Usage
- [ ] Check memory in Android settings
- [ ] App uses < 100 MB
- [ ] No memory leaks over time

### Responsiveness
- [ ] UI is smooth and responsive
- [ ] No lag when toggling monitoring
- [ ] Popup appears instantly
- [ ] No ANR (App Not Responding) dialogs

---

## Code Quality Checks

### Flutter
- [ ] Run `flutter analyze` → no errors
- [ ] Run `flutter test` → all tests pass
- [ ] Code is well-commented
- [ ] No hardcoded secrets

### Django
- [ ] Run `python manage.py test` → all tests pass
- [ ] Run `python manage.py check` → no issues
- [ ] Code follows PEP 8
- [ ] Secrets in .env, not code

---

## Documentation Verification

- [ ] README.md is clear and complete
- [ ] SETUP.md instructions work
- [ ] DEMO_GUIDE.md is accurate
- [ ] All code files have comments
- [ ] API endpoints documented
- [ ] Configuration options explained

---

## Acceptance Criteria (Final Check)

- [ ]  Exactly 3 screens + 1 popup (no extra pages)
- [ ]  Exactly 6 interactive buttons
- [ ]  Monitoring toggle works perfectly (ON/OFF)
- [ ]  OFF stops everything and freezes meter
- [ ]  High risk NEVER sends SMS instantly
- [ ]  ALWAYS shows confirmation popup first
- [ ]  Test High Risk triggers popup reliably
- [ ]  Risk engine is explainable
- [ ]  Persistence: 2-3 spikes required
- [ ]  Decay: score reduces over time
- [ ]  Cooldown: 60 seconds after event
- [ ]  No raw sensor data stored
- [ ]  Code is clean and documented
- [ ]  Tests included and passing
- [ ]  README and demo guide provided

---

## Demo Readiness

- [ ] Backend running and accessible
- [ ] App installed on demo device
- [ ] Onboarding completed
- [ ] Permissions granted
- [ ] Test High Risk works reliably
- [ ] SMS sends successfully
- [ ] Demo script practiced
- [ ] Backup device ready (if needed)
- [ ] Internet connection stable
- [ ] Device charged (>50%)

---

## Known Issues (Document Any)

| Issue | Severity | Workaround |
|-------|----------|------------|
| Example: SMS delay on some carriers | Low | Wait 5-10 seconds |
|  |  |  |
|  |  |  |

---

## Sign-Off

- [ ] All critical tests passed
- [ ] All acceptance criteria met
- [ ] Documentation complete
- [ ] Demo ready
- [ ] Code committed to repository

**Verified By:** ___________________

**Date:** ___________________

**Version:** 1.0.0

---

## Quick Test Script (5 Minutes)

For rapid verification:

```bash
# Terminal 1: Start backend
cd django_backend
source venv/bin/activate
python manage.py runserver

# Terminal 2: Run Flutter
cd flutter_app
flutter run

# On Device:
1. Complete onboarding
2. Toggle Monitoring ON
3. Tap Test High Risk
4. Let timer reach 0
5. Verify SMS received
6. Check backend admin panel

# If all work:  System verified
```
