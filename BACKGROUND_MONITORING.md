# Background Monitoring Feature

## Overview

The app now monitors for danger even when it's in the background or closed! A foreground service runs continuously to detect high-risk situations and automatically send alerts.

## How It Works

### Foreground Service
- Runs as a persistent notification
- Monitors accelerometer and gyroscope sensors
- Calculates risk score in real-time
- Sends alerts automatically when risk >= 70
- Works even when app is closed or screen is off

### Risk Detection
- Detects violent movements (shaking, impacts)
- Requires 3+ high acceleration spikes (>15 m/s²)
- Combines with gyroscope data for confirmation
- Score decays over time if no activity

### Automatic Alerts
- Triggers when risk score reaches 70+
- Gets GPS location automatically
- Sends alert to backend (which notifies contacts)
- 2-minute cooldown between alerts
- Shows notification: " ALERT SENT"

## User Experience

### Starting Monitoring
1. Click "Start" button on home screen
2. Grant location permission if asked
3. Foreground notification appears: "AegisAI Monitoring Active"
4. App monitors in background
5. Message: " Background monitoring started - App will monitor even when closed"

### While Monitoring
- Persistent notification shows:
  - "AegisAI Monitoring"
  - "Risk Score: X | Status: Safe/Medium/HIGH RISK"
- Updates every 5 seconds
- User can close app - monitoring continues

### When Danger Detected
1. Sensors detect violent movement
2. Risk score increases
3. When score >= 70:
   - Gets GPS location
   - Sends alert to backend
   - Backend notifies top 3 contacts
   - Notification changes to " ALERT SENT"
   - 2-minute cooldown starts

### Stopping Monitoring
1. Open app
2. Click "Start" button again (to stop)
3. Foreground service stops
4. Notification disappears

## Permissions Required

### Location (Required)
- Needed for GPS coordinates in alerts
- Must be "Allow all the time" for background monitoring
- Android will show: "Allow AegisAI to access location?"

### Notification (Required)
- Shows foreground service notification
- Shows alert sent notifications
- Android 13+ requires explicit permission

### Battery Optimization (Recommended)
- Disable battery optimization for AegisAI
- Prevents Android from killing the service
- Settings → Apps → AegisAI → Battery → Unrestricted

## Technical Details

### Foreground Service
- Type: Location service
- Update interval: 5 seconds
- Auto-start on boot: Yes
- Wake lock: Yes (keeps CPU awake)
- WiFi lock: Yes (maintains connection)

### Sensor Monitoring
- Accelerometer: Continuous
- Gyroscope: Continuous
- Sampling: Real-time
- Processing: On-device

### Alert Cooldown
- Duration: 2 minutes
- Prevents spam
- Score continues to decay
- New alert possible after cooldown

### Battery Impact
- Moderate battery usage
- Sensors run continuously
- GPS only when alert triggered
- Network only for alerts

## Configuration

### Thresholds (in background_service.dart)
```dart
static const double accelThreshold = 15.0;  // High acceleration
static const int spikeCount = 3;            // Need 3 spikes
static const Duration spikeWindow = Duration(seconds: 4);
static const Duration alertCooldown = Duration(minutes: 2);
```

### Notification Settings
```dart
channelImportance: NotificationChannelImportance.LOW,  // Low priority
priority: NotificationPriority.LOW,                    // Doesn't disturb
```

## Android Manifest Changes

Added permissions:
- `FOREGROUND_SERVICE_LOCATION` - For location-based foreground service
- `POST_NOTIFICATIONS` - For Android 13+ notifications
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` - To prevent service killing

Added service declaration:
```xml
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="location"
    android:exported="true">
</service>
```

## Testing

### Test Background Monitoring
1. Start monitoring
2. Press home button (app goes to background)
3. Shake phone violently for 3-4 seconds
4. Check notification - should show "HIGH RISK"
5. Continue shaking - should send alert
6. Check backend logs - alert should be logged
7. Contacts should receive notifications

### Test App Closed
1. Start monitoring
2. Close app completely (swipe away from recent apps)
3. Notification should still be visible
4. Shake phone violently
5. Alert should still be sent
6. Open app - monitoring should still be active

### Test Cooldown
1. Trigger alert
2. Notification shows " ALERT SENT"
3. Shake phone again immediately
4. No new alert (cooldown active)
5. Wait 2 minutes
6. Shake phone again
7. New alert should be sent

## Troubleshooting

### Service Stops After Closing App

**Cause**: Battery optimization killing service

**Fix**:
1. Settings → Apps → AegisAI
2. Battery → Unrestricted
3. Or disable battery optimization

### No Alerts in Background

**Cause**: Location permission not "Allow all the time"

**Fix**:
1. Settings → Apps → AegisAI
2. Permissions → Location
3. Select "Allow all the time"

### Notification Not Showing

**Cause**: Notification permission denied (Android 13+)

**Fix**:
1. Settings → Apps → AegisAI
2. Notifications → Allow

### High Battery Drain

**Cause**: Continuous sensor monitoring

**Solutions**:
- Only enable when needed
- Increase update interval (currently 5s)
- Reduce sensor sampling rate

## Limitations

### Current Implementation
- Simplified risk detection (no full risk engine in background)
- Basic spike counting (not as sophisticated as foreground)
- No ML context model
- Fixed thresholds (not adaptive)

### Android Restrictions
- Battery optimization may kill service
- Some manufacturers (Xiaomi, Huawei) aggressive with background apps
- Android 12+ has stricter background restrictions

### Future Improvements
1. Full risk engine in background isolate
2. ML-based context awareness
3. Adaptive thresholds
4. Better battery optimization
5. Manufacturer-specific workarounds

## Summary

The app now provides true 24/7 protection with background monitoring. Even if the app is closed, it continues to watch for danger and automatically sends alerts to emergency contacts. The foreground service ensures reliable operation while being battery-conscious.

Key benefits:
-  Works when app is closed
-  Automatic alert sending
-  No user interaction needed
-  Persistent notification for transparency
-  2-minute cooldown prevents spam
-  Battery-efficient design
