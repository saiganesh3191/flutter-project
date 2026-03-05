# Alert Trigger Fix - Auto-Popup Issue Resolved

## Problem
The risk score was reaching 70+ (HIGH) but the alert popup wasn't appearing. The `highRiskTriggered` flag always remained `false` and `_consecutiveHighRiskCount` stayed at 0.

## Root Cause
The trigger confirmation thresholds were too strict:
- `_minGyroMagForConfirmation = 3.2 rad/s` (barely exceeded in real tests, max seen 3.67)
- `_minJerkForConfirmation = 18.0 m/s³` (exceeded but not consistently)
- `_requiredHighRiskSamples = 20` (3 seconds of sustained high risk)

This meant the count wasn't accumulating because the violent evidence check was failing.

## Changes Made

### 1. Lowered Confirmation Thresholds
**File**: `aegis_app/lib/sensor_service.dart`

```dart
// OLD VALUES (too strict)
static const double _minGyroMagForConfirmation = 3.2;  // rad/s
static const double _minJerkForConfirmation = 18.0;    // m/s³
static const int _requiredHighRiskSamples = 20;        // 3 seconds
static const Duration _alertCooldown = Duration(minutes: 5);

// NEW VALUES (easier to trigger for testing)
static const double _minGyroMagForConfirmation = 1.5;  // rad/s (was 3.2)
static const double _minJerkForConfirmation = 12.0;    // m/s³ (was 18.0)
static const int _requiredHighRiskSamples = 8;         // 1.2 seconds (was 20)
static const Duration _alertCooldown = Duration(seconds: 10); // was 5 minutes
```

### 2. Added Detailed Debug Logging
Added comprehensive logging in `_shouldTriggerAlert` method to track:
- Current score and thresholds
- Violent evidence detection (gyro/jerk values vs thresholds)
- Count accumulation/decrement
- Trigger events

**Example logs you'll now see:**
```
 Trigger: score=71, isHigh=true, hasEvidence=true, gyro=2.34/1.5, jerk=15.67/12.0, count=3/8
 Count++ = 4
 Trigger: score=73, isHigh=true, hasEvidence=true, gyro=2.89/1.5, jerk=18.23/12.0, count=4/8
 Count++ = 5
...
 ALERT TRIGGERED! count=8
```

## Testing Instructions

### 1. Run the App
```bash
cd aegis_app
flutter run
```

### 2. Start Monitoring
- Tap "Start" button on home screen
- Wait for sensors to initialize

### 3. Test Auto-Trigger
**Option A: Use Test Button**
- Tap "Test Alert" button
- Should trigger popup after ~1.2 seconds

**Option B: Real Shaking**
- Shake phone vigorously for 1-2 seconds
- Watch console logs for count accumulation
- Popup should appear when count reaches 8

### 4. Watch Console Logs
Look for these patterns:
```
 Trigger: score=XX, isHigh=true/false, hasEvidence=true/false, ...
 Count++ = X  (when accumulating)
 No evidence, count-- = X  (when high score but no motion)
 Reset count=0  (when score drops below 55)
 ALERT TRIGGERED!  (when popup appears)
```

## Expected Behavior

### Before Fix
- Score reaches 70-75
- `highCount` stays at 0
- No popup appears
- Logs show `triggered=false`

### After Fix
- Score reaches 70+
- Count accumulates: 1, 2, 3, 4, 5, 6, 7, 8
- Popup appears when count = 8
- Logs show ` ALERT TRIGGERED!`
- 10 second cooldown before next alert

## Production Tuning

Once testing confirms the popup works, adjust for production:

```dart
// Production values (in sensor_service.dart)
static const int _requiredHighRiskSamples = 15;        // 2.25 seconds
static const Duration _alertCooldown = Duration(minutes: 5); // 5 minutes
static const double _minGyroMagForConfirmation = 2.0;  // tune based on logs
static const double _minJerkForConfirmation = 15.0;    // tune based on logs
```

## Files Modified
- `aegis_app/lib/sensor_service.dart` (lines 31-40, 218-248)

## Next Steps
1. Test with real shaking to verify popup appears
2. Review console logs to see count accumulation
3. Tune thresholds based on real-world testing
4. Adjust cooldown to production value (5 minutes)
5. Consider adding manual panic button as PRIMARY trigger (sensors as backup)
