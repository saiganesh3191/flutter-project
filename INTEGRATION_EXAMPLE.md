# Integration Example - How to Use New Alert System

## Quick Start

Replace your current home_screen.dart alert logic with this:

### 1. Import New Classes

```dart
import '../alert_orchestrator.dart';
import '../alert_sender_impl.dart';
import 'alert_countdown_dialog.dart';
```

### 2. Initialize in State

```dart
class _HomeScreenState extends State<HomeScreen> {
  final SensorService _sensorService = SensorService();
  late final AlertOrchestrator _orchestrator;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize orchestrator
    _orchestrator = AlertOrchestrator(
      sensorService: _sensorService,
      sender: AegisAlertSender(),
      config: const AlertPolicyConfig(
        requiredHighSamples: 10,  // ~1.5s
        cancelWindow: Duration(seconds: 8),
        cooldown: Duration(seconds: 30),
      ),
    );
    
    _setupAlertListener();
  }
```

### 3. Listen to Alert Status

```dart
void _setupAlertListener() {
  _orchestrator.statusStream.listen((status) {
    if (!mounted) return;
    
    switch (status.stage) {
      case AlertStage.idle:
        // Normal monitoring - update UI with score
        setState(() {
          _riskScore = status.score;
          _reasons = status.reasons;
        });
        break;
        
      case AlertStage.arming:
        // Show countdown dialog
        _showCountdownDialog(status);
        break;
        
      case AlertStage.triggered:
        // Alert sent - dismiss dialog and show confirmation
        Navigator.of(context).pop(); // Close countdown dialog
        _showAlertSentConfirmation();
        break;
        
      case AlertStage.cooldown:
        // In cooldown - show status
        setState(() {
          _riskScore = status.score;
          _reasons = ['Cooldown active', ...status.reasons];
        });
        break;
    }
  });
}
```

### 4. Show Countdown Dialog

```dart
void _showCountdownDialog(AlertStatus status) {
  // Only show dialog once (check if already showing)
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
            content: Text('Alert cancelled'),
            backgroundColor: Colors.green,
          ),
        );
      },
    ),
  );
}
```

### 5. Start/Stop Monitoring

```dart
Future<void> _toggleMonitoring() async {
  if (!_isMonitoring) {
    // Start
    await _sensorService.ensurePermissions();
    await _sensorService.start();
    await _orchestrator.start();
    
    setState(() => _isMonitoring = true);
  } else {
    // Stop
    _orchestrator.stop();
    _sensorService.stop();
    
    setState(() => _isMonitoring = false);
  }
}
```

### 6. Test Button

```dart
void _testAlert() {
  if (!_isMonitoring) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Start monitoring first')),
    );
    return;
  }
  
  // Simulate high risk
  _sensorService.simulateHighRisk();
}
```

### 7. Dispose

```dart
@override
void dispose() {
  _orchestrator.dispose();
  _sensorService.dispose();
  super.dispose();
}
```

## Complete Minimal Example

```dart
import 'package:flutter/material.dart';
import '../sensor_service.dart';
import '../alert_orchestrator.dart';
import '../alert_sender_impl.dart';
import 'alert_countdown_dialog.dart';

class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({Key? key}) : super(key: key);

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  final SensorService _sensorService = SensorService();
  late final AlertOrchestrator _orchestrator;
  
  bool _isMonitoring = false;
  int _riskScore = 0;
  List<String> _reasons = [];

  @override
  void initState() {
    super.initState();
    
    _orchestrator = AlertOrchestrator(
      sensorService: _sensorService,
      sender: AegisAlertSender(),
    );
    
    _orchestrator.statusStream.listen((status) {
      if (!mounted) return;
      
      setState(() {
        _riskScore = status.score;
        _reasons = status.reasons;
      });
      
      if (status.stage == AlertStage.arming) {
        _showCountdownDialog(status);
      } else if (status.stage == AlertStage.triggered) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' ALERT SENT!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _orchestrator.dispose();
    _sensorService.dispose();
    super.dispose();
  }

  Future<void> _toggleMonitoring() async {
    if (!_isMonitoring) {
      await _sensorService.ensurePermissions();
      await _sensorService.start();
      await _orchestrator.start();
    } else {
      _orchestrator.stop();
      _sensorService.stop();
    }
    
    setState(() => _isMonitoring = !_isMonitoring);
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AegisAI')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Risk Score: $_riskScore', style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleMonitoring,
              child: Text(_isMonitoring ? 'Stop' : 'Start'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _sensorService.simulateHighRisk(),
              child: const Text('Test Alert'),
            ),
            const SizedBox(height: 20),
            ..._reasons.map((r) => Text(r)).toList(),
          ],
        ),
      ),
    );
  }
}
```

## Migration Checklist

- [ ] Import new classes (AlertOrchestrator, AlertSender, AlertCountdownDialog)
- [ ] Replace old alert logic with AlertOrchestrator
- [ ] Listen to statusStream instead of riskStream
- [ ] Show countdown dialog on AlertStage.arming
- [ ] Handle cancel button press
- [ ] Test cancel window works
- [ ] Test cooldown persists
- [ ] Remove old alert popup code
- [ ] Update test button to use simulateHighRisk()

## Testing

1. **Test Cancel**:
   - Start monitoring
   - Tap "Test Alert"
   - See countdown dialog
   - Tap "CANCEL" before 0
   - Alert should be cancelled

2. **Test Auto-Send**:
   - Start monitoring
   - Tap "Test Alert"
   - Don't cancel
   - Alert should send after 8 seconds

3. **Test Cooldown**:
   - Trigger alert
   - Try to trigger again immediately
   - Should see "Cooldown active"
   - Wait 30 seconds
   - Should be able to trigger again

## Troubleshooting

### Dialog doesn't show
- Check `ModalRoute.of(context)?.isCurrent` before showing
- Make sure you're listening to statusStream
- Check console for "ALERT IN X seconds" logs

### Alert sends immediately
- Check `cancelWindow` duration in config
- Make sure countdown timer is running
- Check console logs for timing

### Cooldown doesn't persist
- Check SharedPreferences is working
- Check console for "Cooldown until X" logs
- Verify app has storage permissions

### False positives
- Increase `requiredHighSamples` (10 → 15)
- Increase `minGyroForEvidence` (1.5 → 2.0)
- Increase `minJerkForEvidence` (12.0 → 15.0)
- See PRODUCTION_READY.md for tuning guide
