#  How to Activate the New Alert System

## Current Status

 **NOT ACTIVE** - The new production code is created but NOT connected to your app yet.

## What's Ready But Not Used

```
 risk_engine.dart          - REPLACED (improved version)
 sensor_service.dart        - REPLACED (now emits RiskFrame)
 alert_orchestrator.dart    - CREATED (not connected)
 alert_sender_impl.dart     - CREATED (not connected)
 alert_countdown_dialog.dart - CREATED (not connected)
 home_screen_updated.dart   - CREATED (ready to replace old one)
```

## How to Activate (2 Options)

### Option 1: Replace home_screen.dart (Recommended)

**Step 1:** Backup your current file
```bash
cd aegis_app/lib/screens
cp home_screen.dart home_screen_old.dart
```

**Step 2:** Replace with updated version
```bash
# Delete old file
rm home_screen.dart

# Rename updated file
mv home_screen_updated.dart home_screen.dart
```

**Step 3:** Run the app
```bash
cd aegis_app
flutter run
```

**Step 4:** Test it
1. Tap "Start" to begin monitoring
2. Tap "Test Alert" button
3. You should see countdown dialog: "ALERT IN 8...7...6..."
4. Tap "I'M SAFE - CANCEL" to test cancel
5. Or let it count down to 0 to test alert sending

### Option 2: Manual Integration (If you want to keep your customizations)

Open your current `home_screen.dart` and make these changes:

**1. Add imports at top:**
```dart
import '../alert_orchestrator.dart';
import '../alert_sender_impl.dart';
import 'alert_countdown_dialog.dart';
```

**2. Add orchestrator in state:**
```dart
class _HomeScreenState extends State<HomeScreen> {
  // ... existing code ...
  late final AlertOrchestrator _orchestrator;
  AlertStage _alertStage = AlertStage.idle;
  StreamSubscription? _alertSubscription;
```

**3. Initialize in initState:**
```dart
@override
void initState() {
  super.initState();
  
  // Add this
  _orchestrator = AlertOrchestrator(
    sensorService: _sensorService,
    sender: AegisAlertSender(),
    config: const AlertPolicyConfig(
      requiredHighSamples: 10,
      cancelWindow: Duration(seconds: 8),
      cooldown: Duration(seconds: 30),
    ),
  );
  
  _setupAlertListener(); // Add this
  
  // ... rest of your existing code ...
}
```

**4. Add alert listener:**
```dart
void _setupAlertListener() {
  _alertSubscription = _orchestrator.statusStream.listen((status) {
    if (!mounted) return;
    
    setState(() {
      _alertStage = status.stage;
      _reasons = status.reasons;
    });

    if (status.stage == AlertStage.arming) {
      _showCountdownDialog(status);
    } else if (status.stage == AlertStage.triggered) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' ALERT SENT!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  });
}

void _showCountdownDialog(AlertStatus status) {
  if (ModalRoute.of(context)?.isCurrent == false) return;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertCountdownDialog(
      remainingSeconds: status.remainingCancelSeconds,
      score: status.score,
      reasons: status.reasons,
      onCancel: () {
        _orchestrator.cancelArming();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Alert cancelled'),
            backgroundColor: Colors.green,
          ),
        );
      },
    ),
  );
}
```

**5. Update _toggleMonitoring:**
```dart
if (_isMonitoring) {
  // Add this line
  await _orchestrator.start();
  await _sensorService.start();
  // ... rest of your code ...
} else {
  // Add this line
  _orchestrator.stop();
  _sensorService.stop();
  // ... rest of your code ...
}
```

**6. Update dispose:**
```dart
@override
void dispose() {
  _alertSubscription?.cancel();
  _orchestrator.dispose(); // Add this
  _sensorService.dispose();
  // ... rest of your code ...
  super.dispose();
}
```

## What You'll Get After Activation

### Before (Current)
-  No cancel window
-  No persistent cooldown
-  Alert sends immediately
-  No way to cancel false alarms

### After (New System)
-  8 second cancel window
-  30 second cooldown (persists across app restart)
-  Beautiful countdown UI
-  "I'M SAFE - CANCEL" button
-  Evidence-based triggering (requires violent motion)
-  Production-ready alert flow

## Testing After Activation

### Test 1: Cancel Window
```
1. Start monitoring
2. Tap "Test Alert"
3. See countdown: "ALERT IN 8...7...6..."
4. Tap "I'M SAFE - CANCEL"
5.  Alert should be cancelled
```

### Test 2: Auto-Send
```
1. Start monitoring
2. Tap "Test Alert"
3. Don't tap cancel
4. Wait for countdown to reach 0
5.  Alert should send (SMS + WhatsApp)
6.  See "Alert Sent" confirmation
```

### Test 3: Cooldown
```
1. Let alert send (from Test 2)
2. Try to trigger another alert immediately
3.  Should see "Cooldown active" in reasons
4. Wait 30 seconds
5.  Should be able to trigger again
```

### Test 4: Cooldown Persistence
```
1. Trigger alert
2. Close app completely
3. Reopen app within 30 seconds
4. Try to trigger alert
5.  Should still be in cooldown
```

## Troubleshooting

### "I replaced the file but nothing changed"
- Run `flutter clean`
- Run `flutter pub get`
- Run `flutter run` again

### "I see errors about AlertOrchestrator"
- Make sure all new files are in `lib/` folder
- Check imports are correct
- Run `flutter pub get`

### "Countdown dialog doesn't show"
- Check console for errors
- Make sure `_setupAlertListener()` is called in `initState`
- Check `_showCountdownDialog` is being called

### "Alert sends immediately without countdown"
- Check `cancelWindow` duration in config
- Should be `Duration(seconds: 8)`
- Check console logs for "ALERT IN X seconds"

## Quick Verification

After activation, check these files exist:

```bash
cd aegis_app/lib
ls -la alert_orchestrator.dart        # Should exist
ls -la alert_sender_impl.dart         # Should exist
ls -la screens/alert_countdown_dialog.dart  # Should exist
ls -la screens/home_screen.dart       # Should be updated version
```

## Need Help?

1. Check console logs for errors
2. Read `INTEGRATION_EXAMPLE.md` for detailed code examples
3. Read `PRODUCTION_READY.md` for system documentation
4. Compare your code with `home_screen_updated.dart`

## Summary

**To activate:**
1. Backup: `cp home_screen.dart home_screen_old.dart`
2. Replace: `mv home_screen_updated.dart home_screen.dart`
3. Run: `flutter run`
4. Test: Tap "Test Alert" and see countdown

**That's it!** The new production system will be active.
