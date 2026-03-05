# AegisAI - Predictive Personal Safety System

Production-ready safety monitoring system with Flutter Android app + Django REST backend.

## Project Structure

```
aegis-ai/
 flutter_app/          # Flutter Android application
 django_backend/       # Django REST API
 README.md            # This file
```

## Quick Start

### Backend Setup (Django)

```bash
cd django_backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env      # Configure your environment
python manage.py migrate
python manage.py runserver
```

### Flutter Setup

```bash
cd flutter_app
flutter pub get
flutter run
```

**Important:** Test on a real Android device with SIM card for SMS functionality.

## Demo Script (30 seconds)

1. Open app (onboarding already completed)
2. Toggle "Monitoring: ON"
3. Tap "Test High Risk" → popup appears with countdown
4. Let timer reach 0 → "Alert Sent" screen appears
5. Tap "Return to Dashboard"
6. Test again and tap "I Am Safe" to show cancel path

## Key Features

- **Minimal UI:** Exactly 3 screens + 1 popup (6 total buttons)
- **Rule-based Risk Engine:** Explainable, with persistence, decay, and cooldown
- **Confirmation First:** Never sends SMS instantly; always shows popup
- **Background Monitoring:** Foreground service for stability
- **Offline Capable:** Works without backend connection

## Testing

```bash
# Flutter tests
cd flutter_app
flutter test

# Django tests
cd django_backend
python manage.py test
```

## Architecture

- **Flutter:** Sensors → Risk Engine → Confirmation → SMS Alert
- **Django:** Device registration, audit logs, optional SMS fallback
- **Security:** No raw sensor data stored, rate limiting, token auth

## Requirements

- Flutter SDK 3.0+
- Python 3.9+
- PostgreSQL (or SQLite for demo)
- Android device with SMS capability

---

**Version:** 1.0 | **Date:** 2026-03-01
