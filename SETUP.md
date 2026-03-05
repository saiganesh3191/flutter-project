# AegisAI Complete Setup Guide

Step-by-step instructions to get the entire system running.

## Prerequisites

### Required Software
- Python 3.9+ ([Download](https://www.python.org/downloads/))
- Flutter SDK 3.0+ ([Install Guide](https://docs.flutter.dev/get-started/install))
- Android Studio or VS Code
- PostgreSQL (optional, can use SQLite)
- Git

### Required Hardware
- Real Android device with SIM card (for SMS testing)
- USB cable for device connection

## Part 1: Django Backend Setup

### Step 1: Navigate to Backend Directory
```bash
cd django_backend
```

### Step 2: Create Virtual Environment
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# macOS/Linux
python3 -m venv venv
source venv/bin/activate
```

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 4: Configure Environment
```bash
# Copy example env file
cp .env.example .env

# Edit .env file with your settings
# For quick start, defaults work with SQLite
```

### Step 5: Run Migrations
```bash
python manage.py migrate
```

### Step 6: Create Admin User (Optional)
```bash
python manage.py createsuperuser
# Follow prompts to create admin account
```

### Step 7: Start Backend Server
```bash
python manage.py runserver
```

Backend should now be running at `http://localhost:8000`

### Step 8: Verify Backend
Open browser to `http://localhost:8000/admin/` and login with admin credentials.

---

## Part 2: Flutter App Setup

### Step 1: Navigate to Flutter Directory
```bash
# Open new terminal
cd flutter_app
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Configure Backend URL

Edit `lib/alert_manager.dart`:

```dart
// For Android emulator
static const String backendUrl = 'http://10.0.2.2:8000';

// For real device, find your computer's IP:
// Windows: ipconfig
// macOS/Linux: ifconfig
// Then use: 'http://YOUR_IP:8000'
```

### Step 4: Connect Android Device

1. Enable Developer Options on Android device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
   
2. Enable USB Debugging:
   - Settings → Developer Options → USB Debugging

3. Connect device via USB

4. Verify connection:
```bash
flutter devices
```

### Step 5: Run Flutter App
```bash
flutter run
```

App should install and launch on your device.

---

## Part 3: First Run Configuration

### Step 1: Complete Onboarding
1. App opens to "AegisAI – Setup"
2. Enter trusted contact name
3. Enter trusted contact phone (with country code, e.g., +1234567890)
4. Tap "Save & Continue"

### Step 2: Grant Permissions
When prompted, grant:
- Location (Allow all the time)
- SMS (Allow)
- Activity Recognition (Allow)

If any permission denied, you'll see: "Permissions required for monitoring."

### Step 3: Test the System
1. You should now see "AegisAI – Monitoring Dashboard"
2. Toggle "Monitoring: ON"
3. Tap "Test High Risk"
4. Popup appears with 5-second countdown
5. Let it reach 0 or tap "Send Alert Now"
6. SMS should be sent to trusted contact
7. Check "Alert Sent" screen

---

## Part 4: Verification

### Verify Backend Logs
1. Go to `http://localhost:8000/admin/`
2. Check:
   - Devices: Should see 1 registered device
   - Trusted Contacts: Should see your contact
   - Alerts: Should see logged alert with location

### Verify SMS
Check trusted contact's phone for SMS with:
- Alert message
- Google Maps link with location

### Verify App Behavior
- Monitoring toggle works (ON/OFF)
- Risk meter updates when monitoring is ON
- Risk meter freezes when monitoring is OFF
- "Test High Risk" always triggers popup
- "I Am Safe" cancels alert and resets score
- "Send Alert Now" immediately sends SMS

---

## Troubleshooting

### Backend Issues

**Problem:** `ModuleNotFoundError: No module named 'decouple'`
```bash
pip install -r requirements.txt
```

**Problem:** Database connection error
```bash
# Use SQLite instead (edit .env)
DB_ENGINE=django.db.backends.sqlite3
DB_NAME=db.sqlite3
```

**Problem:** Port 8000 already in use
```bash
python manage.py runserver 8001
# Update Flutter app's backendUrl accordingly
```

### Flutter Issues

**Problem:** `flutter: command not found`
```bash
# Add Flutter to PATH
# Follow: https://docs.flutter.dev/get-started/install
```

**Problem:** No devices found
```bash
# Check USB debugging enabled
# Try: flutter doctor
```

**Problem:** SMS not sending
- Ensure using real device (not emulator)
- Check SMS permission granted
- Verify device has SIM card
- Check phone number format (+country code)

**Problem:** Location unavailable
- Grant location permission
- Enable GPS on device
- May take a few seconds to acquire location

**Problem:** Background monitoring stops
- Check foreground service notification is visible
- Don't force-close app from recent apps
- Some manufacturers (Xiaomi, Huawei) have aggressive battery optimization

### Permission Issues

**Problem:** Permissions not requested
```bash
# Uninstall and reinstall app
flutter clean
flutter run
```

**Problem:** "Permissions required for monitoring" message
- Go to device Settings → Apps → AegisAI → Permissions
- Manually grant all required permissions
- Restart app

---

## Running Tests

### Backend Tests
```bash
cd django_backend
python manage.py test
```

### Flutter Tests
```bash
cd flutter_app
flutter test
```

---

## Production Deployment

### Backend
1. Set `DEBUG=False` in .env
2. Generate new `SECRET_KEY`
3. Configure PostgreSQL
4. Set proper `ALLOWED_HOSTS`
5. Use gunicorn: `gunicorn aegisai.wsgi:application`
6. Set up Nginx reverse proxy
7. Configure SSL/TLS

### Flutter
1. Update backend URL to production
2. Build release APK:
```bash
flutter build apk --release
```
3. Sign APK for Play Store
4. Test on multiple devices

---

## Next Steps

1. Read `DEMO_GUIDE.md` for demo script
2. Review `ARCHITECTURE.md` for system design
3. Check individual README files in each directory
4. Customize risk thresholds in `risk_engine.dart`
5. Configure Twilio for backend SMS fallback (optional)

---

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review logs in terminal
3. Check Django admin panel for backend issues
4. Use `flutter doctor` for Flutter issues
