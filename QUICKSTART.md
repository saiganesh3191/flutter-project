# AegisAI Quick Start Guide

Get the system running in 5 minutes.

## Prerequisites
- Python 3.9+
- Flutter SDK 3.0+
- Android device with SIM card
- USB cable

## Step 1: Backend (2 minutes)

```bash
cd django_backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate

pip install -r requirements.txt
cp .env.example .env
python manage.py migrate
python manage.py runserver
```

Backend now running at `http://localhost:8000`

## Step 2: Flutter (2 minutes)

```bash
# New terminal
cd flutter_app
flutter pub get

# Connect Android device via USB
flutter devices

# Run app
flutter run
```

## Step 3: First Use (1 minute)

On device:
1. Enter contact name and phone
2. Tap "Save & Continue"
3. Grant all permissions
4. Toggle "Monitoring: ON"
5. Tap "Test High Risk"
6. Watch countdown → SMS sent!

## Verify

- SMS received on contact's phone
- Check `http://localhost:8000/admin/` for logs

## Troubleshooting

**Backend won't start:**
```bash
pip install --upgrade pip
pip install -r requirements.txt
```

**Flutter won't run:**
```bash
flutter doctor
flutter clean
flutter pub get
```

**SMS not sending:**
- Use real device (not emulator)
- Check SMS permission granted
- Verify SIM card installed

## Next Steps

- Read `SETUP.md` for detailed instructions
- Read `DEMO_GUIDE.md` for demo script
- Read `ARCHITECTURE.md` for system design

## Configuration

### Change Backend URL (for real device)

Edit `flutter_app/lib/alert_manager.dart`:
```dart
// Find your computer's IP:
// Windows: ipconfig
// macOS/Linux: ifconfig

static const String backendUrl = 'http://YOUR_IP:8000';
```

### Use SQLite (no PostgreSQL needed)

`.env` already configured for SQLite by default. Just run migrations.

## That's It!

You now have a working safety monitoring system with:
-  Flutter app with 3 screens + 1 popup
-  Django REST backend
-  SMS alerts with location
-  Rule-based risk detection

For full documentation, see `README.md` and other guides.
