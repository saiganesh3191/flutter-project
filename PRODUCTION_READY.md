#  Production-Ready Alert System

## What Changed

Your AegisAI system now has **production-grade alert orchestration** with:

 **Cancel Window** - 8 second countdown before alert fires (user can cancel false alarms)  
 **Persistent Cooldown** - 30 second cooldown saved across app restarts (prevents spam)  
 **Evidence-Based Triggering** - Requires both high score AND violent motion evidence  
 **Hysteresis** - Prevents bouncing between states  
 **Rate Limiting** - Built-in cooldown mechanism  
 **Clean Architecture** - Separation of concerns (sensors → engine → orchestrator → sender)

## New Architecture

```
SensorService (sensors + location)
    ↓ RiskFrame
RiskEngine (scoring + decay)
    ↓ RiskAssessment
AlertOrchestrator (policy + cancel window + cooldown)
    ↓ AlertStatus
AlertSender (SMS + WhatsApp)
```

## Files Added/Modified

### New Files
- `aegis_app/lib/alert_orchestrator.dart` - Production alert flow with cancel window
- `aegis_app/lib/alert_sender_impl.dart` - Integrates with existing SMS service

### Modified Files
- `aegis_app/lib/risk_engine.dart` - Fixed time-based decay (wall clock)
- `aegis_app/lib/sensor_service.dart` - Now emits RiskFrame instead of RiskResult
- `aegis_app/lib/screens/home_screen.dart` - Uses AlertOrchestrator (needs update)

### Unchanged Files
- `aegis_app/lib/alert_manager.dart` - Still handles SMS/WhatsApp sending
- `aegis_app/lib/sms_service.dart` - Still sends via MSG91 + Twilio
- `aegis_app/lib/local_database.dart` - Still stores contacts locally

## Alert Flow

### 1. Monitoring Phase (Idle)
- Sensors read continuously (150ms intervals)
- Risk engine scores each sample (0-100)
- UI shows current score + status

### 2. Detection Phase (Arming)
- Score reaches 70+ for 10 consecutive samples (~1.5 seconds)
- Violent motion evidence detected (gyro ≥ 1.5 rad/s OR jerk ≥ 12 m/s³)
- **8 second countdown starts**
- UI shows "ALERT IN 8...7...6..." with CANCEL button

### 3. Trigger Phase (Triggered)
- If user doesn't cancel within 8 seconds
- SMS + WhatsApp sent to top 3 contacts
- Alert saved to local database
- 30 second cooldown starts (persisted to SharedPreferences)

### 4. Cooldown Phase
- No new alerts for 30 seconds
- Prevents spam from repeated shaking
- Cooldown survives app restart

## Configuration

### Alert Policy (in alert_orchestrator.dart)

```dart
AlertPolicyConfig(
  highThreshold: 70,              // Score to start arming
  resetThreshold: 55,             // Score to reset streak
  requiredHighSamples: 10,        // ~1.5s at 150ms (safer than 8)
  cooldown: Duration(seconds: 30), // Time between alerts
  cancelWindow: Duration(seconds: 8), // Time to cancel
  
  minGyroForEvidence: 1.5,        // rad/s for violent rotation
  minJerkForEvidence: 12.0,       // m/s³ for sudden movement
)
```

### Risk Engine (in sensor_service.dart)

```dart
RiskConfig(
  cooldownAfterHighRisk: Duration(seconds: 10), // Engine cooldown
  spikeDeltaThreshold: 2.5,       // Accel spike threshold
  gyroSpikeThreshold: 3.0,        // Gyro spike threshold
  enableLocationRisk: false,      // Disabled until user configures zones
)
```

## Usage Example

```dart
// Initialize services
final sensorService = SensorService();
final orchestrator = AlertOrchestrator(
  sensorService: sensorService,
  sender: AegisAlertSender(),
  config: AlertPolicyConfig(), // Use defaults or customize
);

// Start monitoring
await sensorService.ensurePermissions();
await sensorService.start();
await orchestrator.start();

// Listen to alert status (for UI)
orchestrator.statusStream.listen((status) {
  switch (status.stage) {
    case AlertStage.idle:
      // Normal monitoring
      print('Score: ${status.score}');
      break;
      
    case AlertStage.arming:
      // Show cancel UI
      print('ALERT IN ${status.remainingCancelSeconds}s');
      // Show CANCEL button
      break;
      
    case AlertStage.triggered:
      // Alert sent
      print('ALERT SENT!');
      break;
      
    case AlertStage.cooldown:
      // Cooldown active
      print('Cooldown active');
      break;
  }
});

// User cancels alert
void onCancelPressed() {
  orchestrator.cancelArming();
}

// Stop monitoring
orchestrator.stop();
sensorService.stop();
```

## Testing

### Test Cancel Window
1. Start monitoring
2. Tap "Test Alert" button
3. Watch countdown: "ALERT IN 8...7...6..."
4. Tap "CANCEL" before countdown reaches 0
5. Alert should be cancelled

### Test Auto-Trigger
1. Start monitoring
2. Shake phone vigorously for 2 seconds
3. Watch countdown start
4. Don't cancel
5. Alert should fire after 8 seconds

### Test Cooldown
1. Trigger an alert (let countdown finish)
2. Try to trigger another alert immediately
3. Should see "Cooldown active" for 30 seconds
4. After 30 seconds, can trigger again

### Test Persistence
1. Trigger an alert
2. Close app completely
3. Reopen app
4. Should still be in cooldown (if < 30 seconds elapsed)

## Tuning for Production

### Scenario 1: Panic Shake (Recommended)
User intentionally shakes phone to trigger alert.

```dart
AlertPolicyConfig(
  requiredHighSamples: 8,         // ~1.2s (faster)
  minGyroForEvidence: 2.0,        // Higher threshold (intentional shake)
  minJerkForEvidence: 15.0,       // Higher threshold
  cancelWindow: Duration(seconds: 5), // Shorter window
  cooldown: Duration(minutes: 2), // Longer cooldown
)
```

### Scenario 2: Fall Detection
Detect sudden falls or impacts.

```dart
AlertPolicyConfig(
  requiredHighSamples: 5,         // ~0.75s (very fast)
  minGyroForEvidence: 1.0,        // Lower threshold (falls have less rotation)
  minJerkForConfirmation: 20.0,   // Higher jerk (sudden impact)
  cancelWindow: Duration(seconds: 10), // Longer window (false positives)
  cooldown: Duration(minutes: 5), // Long cooldown
)

// Also adjust risk engine
RiskConfig(
  spikeDeltaThreshold: 4.0,       // Higher accel threshold for impacts
  jerkThreshold: 25.0,            // Higher jerk threshold
)
```

### Scenario 3: Violent Struggle (Hardest)
Detect physical assault or struggle.

```dart
AlertPolicyConfig(
  requiredHighSamples: 15,        // ~2.25s (longer to avoid false positives)
  minGyroForEvidence: 1.5,        // Moderate threshold
  minJerkForEvidence: 12.0,       // Moderate threshold
  cancelWindow: Duration(seconds: 8), // Standard window
  cooldown: Duration(minutes: 1), // Moderate cooldown
)

// IMPORTANT: This scenario has HIGH false positive rate
// Recommend adding:
// - Manual panic button as PRIMARY trigger
// - Voice activation ("Help me!")
// - Specific shake pattern (3 quick shakes)
```

## Production Checklist

### Before Launch
- [ ] Test cancel window works reliably
- [ ] Test cooldown persists across app restarts
- [ ] Test with real phone shaking (not just simulator)
- [ ] Verify SMS/WhatsApp actually send
- [ ] Test in different scenarios (walking, bus, gym, stairs)
- [ ] Measure false positive rate over 1 week
- [ ] Add manual panic button as PRIMARY trigger
- [ ] Add user settings to adjust sensitivity
- [ ] Add "Test Mode" that doesn't send real alerts
- [ ] Add alert history view
- [ ] Add ability to configure safe zones (home/office)

### Legal/Safety
- [ ] Add disclaimer that sensors are NOT 100% reliable
- [ ] Add terms of service
- [ ] Add privacy policy (location data handling)
- [ ] Add emergency services disclaimer (app doesn't call 911)
- [ ] Add user consent for auto-alerts
- [ ] Add ability to disable auto-alerts (manual only)

### User Education
- [ ] Explain what triggers auto-alerts
- [ ] Explain cancel window
- [ ] Explain cooldown period
- [ ] Show examples of false positives (bus, gym, dancing)
- [ ] Recommend manual panic button for real emergencies
- [ ] Explain that sensors are SUPPORT, not primary detection

## Known Limitations

### False Positives
- **Bus/Train**: Sudden stops trigger high accel
- **Gym**: Weightlifting triggers high gyro + jerk
- **Dancing**: Vigorous dancing triggers high rotation
- **Stairs**: Running up/down stairs triggers high accel
- **Biking**: Bumpy roads trigger high jerk
- **Playing Sports**: Basketball, tennis, etc.

### False Negatives
- **Slow Threats**: Gradual escalation doesn't trigger sensors
- **Minimal Movement**: Threats with little physical motion
- **Phone Not On Person**: Phone in bag/pocket may not detect
- **Phone Battery Dead**: No monitoring when phone off

### Mitigation
1. **Manual Panic Button** - PRIMARY trigger for real emergencies
2. **Cancel Window** - 8 seconds to cancel false alarms
3. **Cooldown** - Prevents spam from repeated false positives
4. **User Education** - Explain limitations clearly
5. **Test Mode** - Let users test without sending real alerts

## Next Steps

1. **Update home_screen.dart** to use AlertOrchestrator
2. **Add cancel UI** - Show countdown + CANCEL button
3. **Add manual panic button** - Big red button for real emergencies
4. **Test thoroughly** - Real-world testing for 1 week
5. **Tune thresholds** - Based on false positive rate
6. **Add user settings** - Let users adjust sensitivity
7. **Add test mode** - Practice without sending real alerts

## Support

For questions or issues:
1. Check console logs for detailed debugging
2. Review TUNING_GUIDE.md for threshold adjustment
3. Test in controlled environment first
4. Measure false positive rate before production launch
