# Risk Engine Tuning Guide

##  CRITICAL: What's Fixed

### 1. Location Risk DISABLED 
**Problem**: Garbage zone (0,0) was adding meaningless risk points.

**Solution**: 
```dart
this.enableLocationRisk = false,  // DISABLED by default
this.locationRiskWeightInZone = 0,
this.locationRiskWeightOutZone = 0,
```

**To Enable Later**:
1. Let users configure "safe zones" (home, office)
2. Store in local database
3. Enable location risk only when zones are configured
4. Higher risk OUTSIDE safe zones

### 2. Detailed Logging Added 
**Problem**: No way to tune thresholds without guessing.

**Solution**: Engine now logs:
- ` NEW MAX ACCEL DELTA: X.XX m/s²` - Track peak accelerations
- ` NEW MAX GYRO: X.XX rad/s` - Track peak rotations
- ` SPIKES: accel=X, gyro=Y` - Track spike counts
- All events with actual sensor values

### 3. Sensor-Based Escalation (Not Sole Decision) 
**Problem**: Real threats often have minimal movement.

**Current State**: 
- Sensors trigger auto-alert at score >= 70
- This is ONE input, not the only brain

**Recommended Additions**:
1. **Manual panic button** (already exists - "Test Alert")
2. **Voice activation** - "Hey Aegis, help!"
3. **Shake pattern** - specific shake sequence
4. **Bluetooth beacon** - disconnect from trusted device
5. **Geofence breach** - leaving safe zone
6. **Time-based** - not checking in after X hours

##  How to Tune Thresholds

### Step 1: Collect Real Data

Run the app for 1-2 days in normal use:

```dart
// In sensor_service.dart, enable detailed logging:
_riskEngine = RiskEngine(
  config: const RiskConfig(
    enableDetailedLogging: true,  //  Already enabled
  ),
  eventLogger: (event) {
    print(' Risk Event: ${event.message} (score=${event.score}, state=${event.state.name})');
  },
);
```

### Step 2: Analyze Logs

Look for these patterns in console output:

**Normal Activities** (should NOT trigger):
```
 NEW MAX ACCEL DELTA: 2.5 m/s²  // Walking
 NEW MAX GYRO: 1.8 rad/s         // Turning
 SPIKES: accel=1, gyro=0         // Single bump
```

**Violent Shaking** (SHOULD trigger):
```
 NEW MAX ACCEL DELTA: 15.2 m/s²  // Strong shake
 NEW MAX GYRO: 8.5 rad/s          // Rapid rotation
 SPIKES: accel=5, gyro=4          // Multiple spikes
```

**Simulated Attack** (SHOULD trigger):
```
 NEW MAX ACCEL DELTA: 20+ m/s²   // Impact
 NEW MAX GYRO: 10+ rad/s          // Struggle
 SPIKES: accel=8, gyro=6          // Sustained violence
```

### Step 3: Adjust Thresholds

Based on your logs, update `RiskConfig`:

```dart
_riskEngine = RiskEngine(
  config: const RiskConfig(
    // TUNE THESE based on logs:
    spikeDeltaThreshold: 3.2,  // If false positives: increase to 4.0-5.0
                                // If missing real events: decrease to 2.5-3.0
    
    gyroSpikeThreshold: 3.5,   // If false positives: increase to 4.5-5.0
                                // If missing real events: decrease to 2.5-3.0
    
    persistenceSpikeCount: 3,  // Require X spikes in window
                                // More = fewer false positives, might miss quick events
    
    persistenceWindow: Duration(seconds: 4),  // Time window for spikes
                                               // Shorter = more sensitive
    
    cooldownAfterHighRisk: Duration(seconds: 60),  // Production: 60s
                                                     // Testing: 10s
  ),
);
```

### Step 4: Test Scenarios

Test these scenarios and verify behavior:

1. **Walking normally** → Score should stay < 20
2. **Running** → Score might reach 20-30, should NOT trigger
3. **Phone in pocket while walking** → Score < 20
4. **Dropping phone** → Brief spike, should NOT trigger (single event)
5. **Shaking phone vigorously** → Score should reach 70+, SHOULD trigger
6. **Simulated struggle** (shake + rotate rapidly) → SHOULD trigger quickly

##  Recommended Threshold Ranges

Based on typical smartphone sensors:

### Conservative (Fewer False Positives)
```dart
spikeDeltaThreshold: 5.0,      // High threshold
gyroSpikeThreshold: 5.0,       // High threshold
persistenceSpikeCount: 4,      // Need 4 spikes
persistenceWindow: Duration(seconds: 3),  // In 3 seconds
```

### Balanced (Recommended)
```dart
spikeDeltaThreshold: 3.2,      // Medium threshold
gyroSpikeThreshold: 3.5,       // Medium threshold
persistenceSpikeCount: 3,      // Need 3 spikes
persistenceWindow: Duration(seconds: 4),  // In 4 seconds
```

### Sensitive (More False Positives)
```dart
spikeDeltaThreshold: 2.5,      // Low threshold
gyroSpikeThreshold: 2.5,       // Low threshold
persistenceSpikeCount: 2,      // Need 2 spikes
persistenceWindow: Duration(seconds: 5),  // In 5 seconds
```

##  Advanced Tuning

### EMA Smoothing (Future Enhancement)

Add exponential moving average for smoother scoring:

```dart
// Instead of instant score jumps, smooth the transitions
_smoothedScore = (_smoothedScore * (1 - alpha)) + (rawScore * alpha);
// alpha = 0.22 (higher = more reactive, lower = smoother)
```

### Jerk Detection (Future Enhancement)

Detect sudden acceleration changes:

```dart
final jerk = (currentAccel - previousAccel) / timeDelta;
if (jerk > jerkThreshold) {
  // Sudden impact detected
}
```

### Pattern Recognition (Future Enhancement)

Detect specific attack patterns:

```dart
// Pattern: High accel → pause → high accel (grab → struggle)
// Pattern: Sustained high gyro (phone being taken)
// Pattern: Rapid direction changes (struggle)
```

##  Production Checklist

Before deploying to real users:

- [ ] Collect 1-2 days of real usage logs
- [ ] Analyze max accel/gyro values
- [ ] Tune thresholds based on data
- [ ] Test all scenarios (walk, run, drop, shake, struggle)
- [ ] Set cooldown to 60 seconds (not 10s)
- [ ] Disable detailed logging (performance)
- [ ] Add manual panic button as primary trigger
- [ ] Add voice activation as backup
- [ ] Consider adding ML model for pattern recognition
- [ ] Add user feedback loop ("Was this a real emergency?")

##  Important Notes

1. **Sensors are NOT enough**: Real threats often have minimal movement (coercion, drugging, etc.)
2. **Manual trigger is PRIMARY**: Sensors should support, not replace, manual activation
3. **False positives are OK**: Better to alert unnecessarily than miss a real emergency
4. **User feedback is critical**: Learn from false positives to improve thresholds
5. **Context matters**: Night time, unsafe locations, etc. should increase sensitivity

##  Monitoring in Production

Track these metrics:

1. **Alert Rate**: Alerts per user per month
2. **False Positive Rate**: User-reported false alarms
3. **True Positive Rate**: Confirmed emergencies
4. **Sensor Patterns**: Common patterns before alerts
5. **User Feedback**: "Was this helpful?" after each alert

##  Continuous Improvement

1. Collect anonymized sensor data before alerts
2. Analyze patterns in confirmed emergencies
3. Train ML model on real data
4. A/B test threshold changes
5. Update thresholds based on user feedback

##  Learning Resources

- [Smartphone Sensor Characteristics](https://developer.android.com/guide/topics/sensors/sensors_overview)
- [Accelerometer Physics](https://en.wikipedia.org/wiki/Accelerometer)
- [Gyroscope Basics](https://en.wikipedia.org/wiki/Gyroscope)
- [Signal Processing for Motion Detection](https://www.sciencedirect.com/topics/engineering/motion-detection)
