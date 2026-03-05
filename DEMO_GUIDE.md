# AegisAI Demo Guide

30-second demo script for judges/stakeholders.

## Pre-Demo Checklist

- [ ] Backend running on `http://localhost:8000`
- [ ] Flutter app installed on real Android device
- [ ] Onboarding completed (contact saved, permissions granted)
- [ ] Device has SIM card for SMS

## Demo Script (30 seconds)

### Step 1: Show Home Screen (5s)
- App opens to "AegisAI – Monitoring Dashboard"
- Point out: "Monitoring: OFF" toggle and risk meter at 0

### Step 2: Enable Monitoring (5s)
- Toggle "Monitoring: ON"
- Explain: "Now actively monitoring accelerometer and location"
- Risk meter shows live updates

### Step 3: Test High Risk (10s)
- Tap "Test High Risk" button
- Popup appears: " High Risk Detected"
- Countdown: 5...4...3...2...1
- Explain: "User has 5 seconds to cancel if false alarm"

### Step 4: Alert Sent (5s)
- Timer reaches 0
- "Alert Sent" screen appears
- Shows contact name and "Location Shared Successfully"
- SMS sent to trusted contact with Google Maps link

### Step 5: Return & Cancel Path (5s)
- Tap "Return to Dashboard"
- Back on home screen, monitoring still ON
- Optional: Test again and tap "I Am Safe" to show cancel path

## Key Points to Emphasize

1. **Minimal UI**: Exactly 3 screens + 1 popup, 6 buttons total
2. **Confirmation First**: Never sends SMS instantly, always shows popup
3. **Explainable**: Risk reasons shown (movement, time context)
4. **Reliable**: Test button always works, no randomness
5. **Production Ready**: Background service, permissions, error handling

## Common Questions

**Q: What if user is actually safe?**
A: Tap "I Am Safe" within 5 seconds to cancel

**Q: How does risk detection work?**
A: Rule-based: requires 2-3 abnormal movement spikes within 3-5 seconds, plus time/location context

**Q: What if phone has no internet?**
A: SMS still sends locally, backend sync happens when online

**Q: Battery impact?**
A: Moderate sampling rate (500ms throttle), location every 20s

**Q: Privacy?**
A: No raw sensor data stored, only risk score summaries

## Troubleshooting

- **Popup doesn't appear**: Ensure monitoring is ON first
- **SMS not received**: Check device has SIM and SMS permission
- **Risk stuck high**: Decay should reduce score after 2-3 seconds of normal movement
- **Background stops**: Foreground service notification should be visible

## Backend Verification

Check admin panel at `http://localhost:8000/admin/`:
- Device registered
- Contact saved
- Alert logged with location coordinates
