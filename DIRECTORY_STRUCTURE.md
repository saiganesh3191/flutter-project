# AegisAI Directory Structure

```
aegis-ai/

 README.md                          # Main project overview
 SETUP.md                           # Complete setup guide
 DEMO_GUIDE.md                      # 30-second demo script
 ARCHITECTURE.md                    # System design documentation
 QUICK_REFERENCE.md                 # Commands and config cheat sheet
 PROJECT_SUMMARY.md                 # Project deliverables summary
 DIRECTORY_STRUCTURE.md             # This file
 .gitignore                         # Git ignore rules

 flutter_app/                       # Flutter Android Application
    README.md                      # Flutter-specific docs
    pubspec.yaml                   # Dependencies
    analysis_options.yaml          # Linting rules
   
    lib/                           # Main source code
       main.dart                  # App entry point (routing)
       storage_service.dart       # SharedPreferences wrapper
       risk_engine.dart           # Rule-based risk scoring
       sensor_service.dart        # Accelerometer + location
       alert_manager.dart         # SMS + backend sync
      
       screens/                   # UI screens (3 + 1 popup)
           onboarding_screen.dart # First-time setup
           home_screen.dart       # Main dashboard
           alert_popup.dart       # Confirmation dialog
           alert_sent_screen.dart # Success screen
   
    test/                          # Tests
       risk_engine_test.dart      # Risk engine unit tests
   
    android/                       # Android configuration
        app/
            build.gradle           # Build configuration
            src/main/
                AndroidManifest.xml # Permissions & services

 django_backend/                    # Django REST API Backend
     README.md                      # Backend-specific docs
     requirements.txt               # Python dependencies
     .env.example                   # Environment config template
     manage.py                      # Django management script
    
     aegisai/                       # Django project
        __init__.py
        settings.py                # Configuration
        urls.py                    # URL routing
        wsgi.py                    # WSGI application
    
     api/                           # API application
         __init__.py
         models.py                  # Database models (4 models)
         serializers.py             # DRF serializers
         views.py                   # API endpoints (4 endpoints)
         urls.py                    # API routes
         admin.py                   # Admin interface
         tests.py                   # API tests
```

## File Purposes

### Root Level Documentation
- **README.md** - Start here for project overview
- **SETUP.md** - Follow for complete installation
- **DEMO_GUIDE.md** - Use for 30-second demo
- **ARCHITECTURE.md** - Understand system design
- **QUICK_REFERENCE.md** - Quick command lookup
- **PROJECT_SUMMARY.md** - See what was delivered

### Flutter App (`flutter_app/`)

#### Core Services
- **main.dart** (80 lines) - App initialization, routing logic
- **storage_service.dart** (60 lines) - Local data persistence
- **risk_engine.dart** (150 lines) - Risk calculation with persistence/decay/cooldown
- **sensor_service.dart** (100 lines) - Sensor management and streaming
- **alert_manager.dart** (120 lines) - SMS sending and backend API calls

#### UI Screens
- **onboarding_screen.dart** (120 lines) - 2 text fields, 1 button, permission requests
- **home_screen.dart** (180 lines) - Toggle, risk meter, explainability, test button
- **alert_popup.dart** (100 lines) - Countdown timer, 2 action buttons
- **alert_sent_screen.dart** (80 lines) - Success message, return button

#### Configuration
- **pubspec.yaml** - Dependencies: sensors_plus, geolocator, telephony, etc.
- **analysis_options.yaml** - Flutter linting rules
- **AndroidManifest.xml** - Permissions and foreground service config
- **build.gradle** - Android build settings

#### Tests
- **risk_engine_test.dart** (150 lines) - 9 unit tests for risk logic

### Django Backend (`django_backend/`)

#### Project Configuration
- **settings.py** (120 lines) - Django settings, REST framework, CORS, database
- **urls.py** (10 lines) - Root URL configuration
- **wsgi.py** (15 lines) - WSGI application entry point

#### API Application
- **models.py** (80 lines) - 4 models: Device, TrustedContact, RiskEvent, Alert
- **serializers.py** (100 lines) - DRF serializers with validation
- **views.py** (90 lines) - 4 API endpoints with throttling
- **urls.py** (10 lines) - API URL patterns
- **admin.py** (30 lines) - Admin interface configuration
- **tests.py** (80 lines) - API endpoint tests

#### Configuration
- **requirements.txt** - Python dependencies
- **.env.example** - Environment variable template
- **manage.py** - Django CLI tool

## Key Directories to Know

### For Development
```
flutter_app/lib/          # All Flutter source code
django_backend/api/       # All backend logic
```

### For Configuration
```
flutter_app/pubspec.yaml              # Flutter dependencies
flutter_app/android/app/src/main/     # Android config
django_backend/.env                   # Backend environment
```

### For Testing
```
flutter_app/test/         # Flutter tests
django_backend/api/tests.py  # Backend tests
```

### For Documentation
```
*.md files in root        # All documentation
```

## File Count Summary

| Category | Count |
|----------|-------|
| Flutter Dart files | 9 |
| Flutter config files | 4 |
| Django Python files | 8 |
| Django config files | 3 |
| Documentation files | 7 |
| Test files | 2 |
| **Total** | **33** |

## Important Files for Customization

### Change Risk Thresholds
```
flutter_app/lib/risk_engine.dart
```

### Change Backend URL
```
flutter_app/lib/alert_manager.dart
```

### Change Countdown Duration
```
flutter_app/lib/screens/alert_popup.dart
```

### Configure Database
```
django_backend/.env
```

### Enable Twilio SMS
```
django_backend/.env
```

## Files You'll Edit Most

1. `flutter_app/lib/risk_engine.dart` - Adjust risk logic
2. `flutter_app/lib/alert_manager.dart` - Backend URL, SMS format
3. `django_backend/.env` - Environment configuration
4. `flutter_app/lib/screens/home_screen.dart` - UI customization

## Files You Shouldn't Need to Edit

- `manage.py` - Django CLI (standard)
- `wsgi.py` - WSGI config (standard)
- `__init__.py` files - Python package markers
- `build.gradle` - Android build (unless changing SDK versions)

## Generated/Ignored Files (Not in Repo)

```
flutter_app/build/        # Flutter build output
flutter_app/.dart_tool/   # Flutter tools
django_backend/venv/      # Python virtual environment
django_backend/db.sqlite3 # SQLite database
django_backend/.env       # Environment secrets
```

These are in `.gitignore` and created during setup.
