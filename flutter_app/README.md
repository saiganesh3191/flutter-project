# AegisAI Flutter App

Minimal safety monitoring app with rule-based risk detection.

## Setup

### Prerequisites
- Flutter SDK 3.0+
- Android Studio or VS Code
- Real Android device with SIM card (for SMS testing)

### Installation

```bash
flutter pub get
```

### Configuration

Update backend URL in `lib/alert_manager.dart`:
```dart
static const String backendUrl = 'http://YOUR_IP:8000';
```

For Android emulator, use `http://10.0.2.2:8000`

### Run

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── storage_service.dart         # Local storage wrapper
├── risk_engine.dart             # Rule-based risk scoring
├── sensor_service.dart          # Sensor management
├── alert_manager.dart           # SMS and backend integration
└── screens/
    ├── onboarding_screen.dart   # First-time setup
    ├── home_screen.dart         # Main dashboard
    ├── alert_popup.dart         # Confirmation dialog
    └── alert_sent_screen.dart   # Success screen
```

## Testing

```bash
flutter test
```

## Key Features

- Exactly 3 screens + 1 popup (6 buttons total)
- Rule-based risk engine with persistence and decay
- Confirmation popup before SMS (never instant send)
- Background monitoring with foreground service
- Offline capable (works without backend)

## Permissions Required

- Location (fine and coarse)
- SMS (send and read)
- Activity Recognition
- Foreground Service

## Demo Flow

1. Complete onboarding (save contact + grant permissions)
2. Toggle "Monitoring: ON"
3. Tap "Test High Risk" → popup appears
4. Let countdown reach 0 → SMS sent
5. Tap "Return to Dashboard"

## Troubleshooting

- SMS not sending: Check permissions and use real device
- Background monitoring stops: Ensure foreground service is enabled
- High risk stuck: Check decay and cooldown logic in risk_engine.dart
