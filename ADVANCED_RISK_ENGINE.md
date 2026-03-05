# Advanced Risk Engine Integration

## Overview

Integrated a sophisticated risk detection engine with multi-sensor fusion, time-based weighting, location zones, and intelligent cooldown periods.

## Key Features

### 1. Multi-Sensor Fusion
- **Accelerometer**: Detects sudden movements and impacts
- **Gyroscope**: Detects rotational movements (phone snatching, struggling)
- **Fusion Detection**: Combines both sensors for higher confidence

### 2. Intelligent Pattern Detection

**Persistent Spike Detection:**
- Requires 3+ accelerometer spikes within 4 seconds
- Requires 2+ gyroscope spikes for fusion confirmation
- Reduces false positives from normal phone usage

**Gyro-Only "Snatch" Detection:**
- Detects phone snatching (3+ gyro spikes in 2 seconds)
- Lower weight than fusion events
- Optional feature (can be disabled)

### 3. Context-Aware Scoring

**Time-Based Weighting:**
- Night time (10 PM - 5 AM): 10 points
- Day time: 3 points
- Higher risk during vulnerable hours

**Location-Based Weighting:**
- Inside danger zone: 10 points
- Outside danger zone: 4 points
- Uses GPS coordinates and geofencing

**Movement Intensity:**
- High intensity (8+ m/s²): 28 points
- Medium intensity (5-8 m/s²): 18 points
- Low intensity: 10 points

**Context Risk:**
- ML model input (0.0 - 1.0)
- Max weight: 15 points
- Can be enhanced with external data

### 4. Smart Cooldown System

**Prevents Alert Spam:**
- 60-second cooldown after high-risk event
- Score continues to decay during cooldown
- No new alerts until cooldown expires

**Score Decay:**
- Decays by 4 points every 2 seconds
- Only decays if no spikes for 8 seconds
- Prevents score from staying high indefinitely

### 5. Physics-Based Thresholds

**Accelerometer:**
- Baseline: 9.81 m/s² (gravity)
- Spike threshold: 3.2 m/s² delta from gravity
- Prevents false positives from normal movement

**Gyroscope:**
- Spike threshold: 3.5 rad/s
- Tunable based on device characteristics
- Detects rotational violence

## Risk Scoring

### Score Ranges
- **0-39**: Safe (green)
- **40-69**: Medium risk (orange)
- **70-100**: High risk (red) - Triggers alert

### Score Calculation
```
score = movement_weight + time_weight + location_weight + context_weight
```

**Fusion Boost:**
- +8 points if both accel AND gyro detect violence
- Confirms genuine threat vs. false positive

**Max Increment:**
- Capped at 45 points per event
- Prevents single burst from maxing out score

## Configuration

All thresholds are configurable via `RiskConfig`:

```dart
const RiskConfig(
  spikeDeltaThreshold: 3.2,        // Accel spike threshold
  gyroSpikeThreshold: 3.5,         // Gyro spike threshold
  persistenceSpikeCount: 3,        // Required accel spikes
  persistenceGyroCount: 2,         // Required gyro spikes
  cooldownAfterHighRisk: Duration(seconds: 60),
  scoreDecayStep: 4,               // Decay rate
  timeRiskWeightNight: 10,         // Night time weight
  timeRiskWeightDay: 3,            // Day time weight
  // ... more config options
)
```

## Integration

### Sensor Service
- Samples sensors at 150ms intervals
- Combines accelerometer + gyroscope data
- Feeds samples to risk engine
- Converts assessment to UI-compatible format

### Risk Engine
- Processes sensor samples
- Maintains spike history queues
- Calculates weighted risk scores
- Triggers alerts at score >= 70

### Event Logging
- Logs all risk events with timestamps
- Includes score, state, and detailed reasons
- Useful for debugging and tuning

## Benefits

 **Reduced False Positives**: Multi-sensor fusion + persistence requirements
 **Context Awareness**: Time, location, and external context
 **Smart Cooldown**: Prevents alert spam
 **Tunable**: All thresholds configurable
 **Physics-Based**: Uses real physics for accurate detection
 **Battery Efficient**: Intelligent sampling and throttling

## Testing

### Simulate High Risk
```dart
sensorService.simulateHighRisk();
```

This generates a series of violent movements to test the system:
- 5 samples with high acceleration (15-23 m/s²)
- High rotation (5-9 rad/s)
- High context risk (0.8)
- Should trigger high-risk alert

### Real-World Testing
1. Enable monitoring
2. Shake phone violently for 2-3 seconds
3. Should detect persistent spikes
4. Score should increase to 70+
5. Alert should trigger
6. 60-second cooldown should activate

## Future Enhancements

1. **ML Context Model**: Train model on user behavior patterns
2. **Adaptive Thresholds**: Auto-tune based on device and user
3. **Audio Analysis**: Add microphone data for scream detection
4. **Heart Rate**: Integrate wearable data if available
5. **Crowd-Sourced Zones**: Community-reported danger zones

## Technical Details

### Sample Rate
- Accelerometer: Continuous (hardware rate)
- Gyroscope: Continuous (hardware rate)
- Risk Engine: 150ms sampling
- Location: Every 20 seconds

### Memory Usage
- Spike queues: ~10-20 timestamps each
- Minimal memory footprint
- No sensor data stored long-term

### CPU Usage
- Lightweight calculations
- No heavy ML inference (yet)
- Efficient queue management

## Troubleshooting

### Too Many False Positives
- Increase `spikeDeltaThreshold` (try 4.0)
- Increase `persistenceSpikeCount` (try 4)
- Increase `gyroSpikeThreshold` (try 4.5)

### Missing Real Events
- Decrease `spikeDeltaThreshold` (try 2.5)
- Decrease `persistenceSpikeCount` (try 2)
- Enable `enableGyroOnlyEvent`

### Score Stays High
- Decrease `decayAfterNoSpike` (try 5 seconds)
- Increase `scoreDecayStep` (try 6)

## Summary

The advanced risk engine provides production-ready violence detection with:
- Multi-sensor fusion for accuracy
- Context-aware scoring for intelligence
- Smart cooldown for usability
- Configurable thresholds for tuning

It's ready to use and can be enhanced with ML models and additional sensors in the future!
