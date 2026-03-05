#  AegisAI Risk Scoring Formula

## Complete Risk Score Formula

```
FINAL_RISK_SCORE = (
    MOTION_SCORE +
    PERSISTENCE_SCORE +
    FUSION_BONUS +
    TIME_MULTIPLIER +
    LOCATION_FACTOR +
    CONTEXT_WEIGHT
) × NIGHT_MODE_MULTIPLIER

Range: 0-100
```

## Component Breakdown

### 1. MOTION_SCORE (0-105 points)

```
MOTION_SCORE = ACCEL_SCORE + GYRO_SCORE + JERK_SCORE

ACCEL_SCORE = scale(max_accel_delta, 0→10, output: 0→40)
GYRO_SCORE = scale(max_gyro_mag, 0→8, output: 0→30)
JERK_SCORE = scale(max_jerk, 0→40, output: 0→35)
```

**What it measures:**
- Acceleration changes (sudden movements)
- Rotation speed (phone spinning/shaking)
- Jerk (rate of acceleration change)

### 2. PERSISTENCE_SCORE (0-25 points)

```
PERSISTENCE_SCORE = (accel_spikes × 2) + (gyro_spikes × 3) + (jerk_spikes × 2)
Capped at: 25 points

Where:
- accel_spikes = count of samples where accel_delta ≥ 2.5 m/s²
- gyro_spikes = count of samples where gyro_mag ≥ 3.0 rad/s
- jerk_spikes = count of samples where jerk ≥ 16.0 m/s³
```

**What it measures:**
- How many times violent motion occurred in 4-second window
- More spikes = more sustained threat

### 3. FUSION_BONUS (0-10 points)

```
FUSION_BONUS = 10 if (2+ signal types spiking) else 0

Signal types:
- Accel spiking: accel_spikes ≥ 2
- Gyro spiking: gyro_spikes ≥ 2
- Jerk spiking: jerk_spikes ≥ 2

Confirmed if: (accel AND gyro) OR (accel AND jerk) OR (gyro AND jerk)
```

**What it measures:**
- Multi-sensor confirmation (more reliable than single sensor)
- Reduces false positives

### 4. TIME_MULTIPLIER (×1.0 to ×1.5)

```
DAY MODE (6am - 9pm):
    TIME_WEIGHT = 3 points
    MULTIPLIER = 1.0

NIGHT MODE (10pm - 5am):
    TIME_WEIGHT = 10 points
    MULTIPLIER = 1.3 (30% more sensitive)
    
TRANSITION (9pm-10pm, 5am-6am):
    TIME_WEIGHT = 6 points
    MULTIPLIER = 1.15 (15% more sensitive)
```

**What it measures:**
- Higher risk at night (more dangerous)
- Gradual transition (not sudden jumps)

### 5. LOCATION_FACTOR (0-10 points)

```
LOCATION_FACTOR = {
    10 points if OUTSIDE safe zone (unsafe area)
    0 points if INSIDE safe zone (home/office)
    0 points if location disabled
}
```

**What it measures:**
- Location-based risk (unsafe areas)
- Currently disabled (needs user configuration)

### 6. CONTEXT_WEIGHT (0-15 points)

```
CONTEXT_WEIGHT = contextRisk × 15

Where contextRisk ∈ [0.0, 1.0]:
- 0.45 during day (low context risk)
- 0.65 at night (higher context risk)
```

**What it measures:**
- Environmental context
- Time-based ambient risk

### 7. NIGHT_MODE_MULTIPLIER (×1.0 to ×1.5)

```
NIGHT_MODE_MULTIPLIER = {
    1.5× if 11pm - 4am (peak danger hours)
    1.3× if 10pm-11pm or 4am-5am (transition)
    1.0× if 6am - 9pm (day time)
}
```

**What it does:**
- Amplifies entire score at night
- Makes system more sensitive when needed

## Example Calculations

### Example 1: Vigorous Shaking at Night

```
Input:
- max_accel_delta = 8.5 m/s²
- max_gyro_mag = 4.2 rad/s
- max_jerk = 28.0 m/s³
- accel_spikes = 8
- gyro_spikes = 6
- jerk_spikes = 5
- time = 11:30 PM (night)

Calculation:
ACCEL_SCORE = scale(8.5, 0→10, 0→40) = 34
GYRO_SCORE = scale(4.2, 0→8, 0→30) = 30 (capped)
JERK_SCORE = scale(28.0, 0→40, 0→35) = 24.5

MOTION_SCORE = 34 + 30 + 24.5 = 88.5

PERSISTENCE_SCORE = (8×2) + (6×3) + (5×2) = 16 + 18 + 10 = 44 → capped at 25

FUSION_BONUS = 10 (all 3 signals spiking)

TIME_WEIGHT = 10 (night)

CONTEXT_WEIGHT = 0.65 × 15 = 9.75

BASE_SCORE = 88.5 + 25 + 10 + 10 + 9.75 = 143.25

NIGHT_MULTIPLIER = 1.5× (11:30 PM)

FINAL_SCORE = 143.25 × 1.5 = 214.875 → capped at 100

Result: 100 (HIGH RISK - TRIGGERS ALERT)
```

### Example 2: Same Shaking During Day

```
Same motion but at 2:00 PM:

BASE_SCORE = 88.5 + 25 + 10 + 3 + 6.75 = 133.25
NIGHT_MULTIPLIER = 1.0× (day)
FINAL_SCORE = 133.25 × 1.0 = 133.25 → capped at 100

Result: 100 (HIGH RISK - TRIGGERS ALERT)
```

### Example 3: Walking at Night

```
Input:
- max_accel_delta = 3.2 m/s²
- max_gyro_mag = 0.8 rad/s
- max_jerk = 8.5 m/s³
- accel_spikes = 2
- gyro_spikes = 0
- jerk_spikes = 1
- time = 11:30 PM (night)

Calculation:
ACCEL_SCORE = scale(3.2, 0→10, 0→40) = 12.8
GYRO_SCORE = scale(0.8, 0→8, 0→30) = 3.0
JERK_SCORE = scale(8.5, 0→40, 0→35) = 7.4

MOTION_SCORE = 12.8 + 3.0 + 7.4 = 23.2

PERSISTENCE_SCORE = (2×2) + (0×3) + (1×2) = 6

FUSION_BONUS = 0 (only accel spiking)

TIME_WEIGHT = 10 (night)

CONTEXT_WEIGHT = 0.65 × 15 = 9.75

BASE_SCORE = 23.2 + 6 + 0 + 10 + 9.75 = 48.95

NIGHT_MULTIPLIER = 1.5× (11:30 PM)

FINAL_SCORE = 48.95 × 1.5 = 73.425 → 73

Result: 73 (HIGH RISK but needs evidence to trigger)
Evidence check: gyro=0.8 < 1.5, jerk=8.5 < 12.0
Result: NO EVIDENCE - WON'T TRIGGER 
```

## Night Mode Enhancement

### Why Night Mode?

**Statistics:**
- 60% of assaults occur between 10pm-4am
- Reduced visibility
- Fewer witnesses
- Slower emergency response
- Higher user vulnerability

### How It Works

1. **Increased Sensitivity (1.3-1.5× multiplier)**
   - Same motion = higher score at night
   - Triggers faster at night

2. **Lower Evidence Threshold**
   - Day: gyro ≥ 1.5 rad/s
   - Night: gyro ≥ 1.2 rad/s (20% lower)

3. **Shorter Trigger Time**
   - Day: 10 samples (1.5s)
   - Night: 8 samples (1.2s)

4. **Longer Cooldown**
   - Day: 30 seconds
   - Night: 60 seconds (more cautious)

## Thresholds Summary

### Motion Thresholds
```
Accel Delta Spike: ≥ 2.5 m/s²
Gyro Spike: ≥ 3.0 rad/s
Jerk Spike: ≥ 16.0 m/s³
```

### Evidence Thresholds (for triggering)
```
Day Mode:
- Gyro: ≥ 1.5 rad/s
- Jerk: ≥ 12.0 m/s³

Night Mode:
- Gyro: ≥ 1.2 rad/s (20% lower)
- Jerk: ≥ 10.0 m/s³ (17% lower)
```

### Trigger Thresholds
```
High Risk: score ≥ 70
Reset: score ≤ 55

Day: 10 consecutive high samples
Night: 8 consecutive high samples
```

## Visual Formula Flow

```

  SENSOR DATA (150ms intervals)                          
  • Accelerometer (x, y, z)                              
  • Gyroscope (gx, gy, gz)                               
  • Location (lat, lon)                                  
  • Timestamp                                            

                        ↓

  FEATURE EXTRACTION                                     
  • accel_magnitude = √(x² + y² + z²)                   
  • accel_delta = |accel_mag - 9.81|                    
  • gyro_magnitude = √(gx² + gy² + gz²)                 
  • jerk = Δ(accel_delta) / Δt                          

                        ↓

  ROLLING WINDOW (4 seconds)                             
  • Store last 26 samples                                
  • Track max values                                     
  • Count spikes                                         

                        ↓

  SCORE CALCULATION                                      
  BASE = Motion + Persistence + Fusion + Time + Context  
  FINAL = BASE × Night_Multiplier                        
  FINAL = clamp(FINAL, 0, 100)                          

                        ↓

  EMA SMOOTHING                                          
  score_ema = (α × instant) + ((1-α) × score_ema)       
  α = 0.22 (smoothing factor)                            

                        ↓

  TIME-BASED DECAY                                       
  score -= decay_rate × Δt                               
  decay_rate = 1.8 points/second                         

                        ↓

  ALERT POLICY                                           
  IF score ≥ 70 AND has_evidence:                        
    count++                                              
  IF count ≥ threshold:                                  
    TRIGGER ALERT                                        

```

## Tuning Guide

### Too Many False Positives?
1. Increase evidence thresholds
2. Increase required sample count
3. Reduce night multiplier

### Not Triggering When Needed?
1. Decrease evidence thresholds
2. Decrease required sample count
3. Increase night multiplier

### False Positives Only at Night?
1. Reduce night multiplier (1.5 → 1.3)
2. Keep day thresholds same

### Not Sensitive Enough at Night?
1. Increase night multiplier (1.5 → 1.8)
2. Lower night evidence thresholds more
