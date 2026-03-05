# AegisAI Quick Reference

## Project Stats
- **UI Screens:** 3 + 1 popup
- **Interactive Buttons:** 6 total
- **Backend Endpoints:** 4
- **Risk Thresholds:** Safe (0-39), Medium (40-69), High (70+)
- **Countdown Timer:** 5 seconds
- **Cooldown Period:** 60 seconds
- **Decay Interval:** 2 seconds (-10 points)

## File Structure

### Flutter App (lib/)
```
main.dart                 # Entry point, routing
storage_service.dart      # SharedPreferences wrapper
risk_engine.dart          # Rule-based scoring (150 lines)
sensor_service.dart       # Accelerometer + location
alert_manager.dart        # SMS + backend sync
screens/
   onboarding_screen.dart    # 2 fields, 1 button
   home_screen.dart          # Toggle, meter, test button
   alert_popup.dart          # Countdown, 2 buttons
   alert_sent_screen.dart    # Success message, 1 button
```

### Django Backend
```
aegisai/
   settings.py         # Configuration
   urls.py            # URL routing
   wsgi.py            # WSGI application
api/
   models.py          # 4 models (Device, Contact, RiskEvent, Alert)
   serializers.py     # DRF serializers
   views.py           # 4 API endpoints
   urls.py            # API routes
   admin.py           # Admin interface
   tests.py           # API tests
```

## Commands Cheat Sheet

### Backend
```bash
# Setup
cd django_backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env

# Run
python manage.py migrate
python manage.py runserver

# Test
python manage.py test
```

### Flutter
```bash
# Setup
cd flutter_app
flutter pub get

# Run
flutter run

# Test
flutter test

# Build
flutter build apk --release
```

## API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/v1/device/register/` | Get device token |
| POST | `/api/v1/contacts/` | Save trusted contact |
| POST | `/api/v1/risk-events/` | Log risk score |
| POST | `/api/v1/alerts/` | Log alert + optional SMS |

## Risk Engine Parameters

```dart
// Thresholds
safeThreshold = 39
mediumThreshold = 69
abnormalMagnitudeThreshold = 20.0

// Persistence
requiredSpikes = 2
spikeWindow = 4 seconds

// Decay
decayInterval = 2 seconds
decayAmount = 10

// Cooldown
cooldownDuration = 60 seconds

// Time context
nightHourStart = 22 (10 PM)
```

## Sensor Configuration

```dart
// Accelerometer
throttleDuration = 500ms

// Location
locationInterval = 20 seconds
accuracy = LocationAccuracy.high
```

## Permissions Required

- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`
- `android.permission.SEND_SMS`
- `android.permission.READ_SMS`
- `android.permission.ACTIVITY_RECOGNITION`
- `android.permission.FOREGROUND_SERVICE`
- `android.permission.WAKE_LOCK`

## UI Button Count (6 Total)

1. Onboarding: "Save & Continue"
2. Home: Monitoring toggle (ON/OFF)
3. Home: "Test High Risk"
4. Popup: "I Am Safe"
5. Popup: "Send Alert Now"
6. Alert Sent: "Return to Dashboard"

## Color Scheme

- **Safe (0-39):** Green
- **Medium (40-69):** Orange/Yellow
- **High (70+):** Red
- **Theme:** Clean, professional, dark-friendly

## SMS Format

```
 ALERT from [Name]
Reason: [Reason]
Location: https://www.google.com/maps?q=[lat],[lng]
```

## Testing Checklist

- [ ] Onboarding saves contact
- [ ] Permissions requested
- [ ] Monitoring toggle works
- [ ] Risk meter updates when ON
- [ ] Risk meter freezes when OFF
- [ ] Test High Risk triggers popup
- [ ] Countdown works (5 seconds)
- [ ] "I Am Safe" cancels and resets
- [ ] "Send Alert Now" sends SMS
- [ ] Timer auto-sends at 0
- [ ] SMS received with location link
- [ ] Backend logs alert
- [ ] Return to dashboard works
- [ ] Background monitoring stable

## Common Customizations

### Change Risk Thresholds
Edit `flutter_app/lib/risk_engine.dart`:
```dart
static const int safeThreshold = 39;      // Change here
static const int mediumThreshold = 69;    // Change here
```

### Change Countdown Duration
Edit `flutter_app/lib/screens/alert_popup.dart`:
```dart
static const int countdownSeconds = 5;    // Change here
```

### Change Backend URL
Edit `flutter_app/lib/alert_manager.dart`:
```dart
static const String backendUrl = 'http://YOUR_IP:8000';
```

### Enable Twilio SMS
Edit `django_backend/.env`:
```
ENABLE_SERVER_SMS=True
TWILIO_ACCOUNT_SID=your_sid
TWILIO_AUTH_TOKEN=your_token
TWILIO_PHONE_NUMBER=+1234567890
```

## Acceptance Criteria Checklist

- [x] Exactly 3 screens + 1 popup
- [x] Exactly 6 interactive buttons
- [x] Monitoring toggle start/stop works perfectly
- [x] High risk NEVER sends SMS instantly
- [x] Test High Risk always triggers popup
- [x] Risk engine has persistence + decay + cooldown
- [x] No raw sensor data stored
- [x] Code is clean and documented
- [x] Tests included
- [x] README and demo guide provided

## Performance Targets

- **Battery:** Moderate drain (throttled sensors)
- **Memory:** < 100 MB
- **Network:** Minimal (only logs, not continuous)
- **Storage:** < 10 MB local data
- **Response Time:** < 100ms for risk calculation

## Security Checklist

- [x] Device token authentication
- [x] Rate limiting (10 alerts/hour)
- [x] Contact validation
- [x] No raw sensor data storage
- [x] Input sanitization
- [x] CORS configured
- [x] Environment-based secrets
