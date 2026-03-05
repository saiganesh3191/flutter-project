#  Fixed: "Score high but weak evidence" Issue

## Problem You Found

Your log showed:
```
Reasons: High risk score, Sustained: 10/10, Motion confirmed, Score high but weak evidence
```

This is a **contradiction**:
- "Sustained: 10/10" means count reached 10
- "Motion confirmed" means evidence was seen
- "Score high but weak evidence" means current frame has NO evidence

## Root Cause

The old logic was:
```dart
if (isHigh) {
  _highCount++;              //  Always increment
  if (hasEvidence) _evidenceSeen = true;
}
```

This meant:
1. Score reaches 70+ → count increments
2. Even if gyro/jerk too low → count still increments
3. Eventually reaches 10 → triggers alert
4. But current frame has weak evidence → shows confusing message

## The Fix

New logic:
```dart
if (isHigh) {
  if (hasEvidence) {
    _highCount++;            //  Only increment with evidence
    _evidenceSeen = true;
  } else {
    if (_highCount > 0) _highCount -= 1;  //  Decrement if no evidence
  }
}
```

Now:
1. Score reaches 70+ AND has evidence → count increments
2. Score reaches 70+ but NO evidence → count decrements
3. Must have BOTH high score AND evidence to trigger
4. No more contradictory messages

## What Changed

### Before (Wrong)
```
Frame 1: score=71, gyro=0.5, jerk=5.0  → count=1 (no evidence but counted!)
Frame 2: score=72, gyro=0.6, jerk=6.0  → count=2 (no evidence but counted!)
Frame 3: score=73, gyro=2.0, jerk=15.0 → count=3 (has evidence, counted)
...
Frame 10: score=75, gyro=0.8, jerk=7.0 → count=10 (no evidence but triggers!)
```

### After (Correct)
```
Frame 1: score=71, gyro=0.5, jerk=5.0  → count=0 (no evidence, not counted)
Frame 2: score=72, gyro=0.6, jerk=6.0  → count=0 (no evidence, not counted)
Frame 3: score=73, gyro=2.0, jerk=15.0 → count=1 (has evidence, counted!)
Frame 4: score=74, gyro=2.5, jerk=18.0 → count=2 (has evidence, counted!)
...
Frame 12: score=75, gyro=2.8, jerk=20.0 → count=10 (has evidence, triggers!)
```

## New Console Logs

You'll now see detailed logging:

### When Evidence Found
```
 AlertOrch: score=73, gyro=2.34/1.5, jerk=15.67/12.0, hasEvidence=true, count=3/10
 Evidence found! Count++ = 4
```

### When No Evidence
```
 AlertOrch: score=71, gyro=0.85/1.5, jerk=8.23/12.0, hasEvidence=false, count=3/10
 High score but NO evidence - count-- = 2
```

### When Ready to Arm
```
 AlertOrch: score=75, gyro=2.89/1.5, jerk=18.45/12.0, hasEvidence=true, count=10/10
 Evidence found! Count++ = 10
 READY TO ARM! count=10, evidenceSeen=true
```

## Test It Now

```bash
cd aegis_app
flutter run
```

Then:
1. Tap "Start"
2. Tap "Test Alert"
3. Watch console logs
4. You should see:
   - Multiple " Evidence found!" messages
   - Count incrementing: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
   - " READY TO ARM!"
   - Countdown dialog appears

## What This Prevents

### False Positives from "Soft" High Scores

**Scenario:** Phone in pocket while walking
- Score might reach 70+ from walking motion
- But gyro/jerk too low (not violent enough)
- Old system: Would trigger after 10 frames
- New system: Count doesn't accumulate, won't trigger 

**Scenario:** Phone on table, slight vibration
- Score might reach 70+ from vibration
- But gyro/jerk too low
- Old system: Would trigger
- New system: Won't trigger 

## Thresholds

Current evidence thresholds:
```dart
minGyroForEvidence: 1.5 rad/s
minJerkForEvidence: 12.0 m/s³
```

**At least ONE must be exceeded** for evidence to count.

### If Too Sensitive (False Positives)
Increase thresholds:
```dart
minGyroForEvidence: 2.0,  // was 1.5
minJerkForEvidence: 15.0, // was 12.0
```

### If Not Sensitive Enough (Doesn't Trigger)
Decrease thresholds:
```dart
minGyroForEvidence: 1.2,  // was 1.5
minJerkForEvidence: 10.0, // was 12.0
```

## Expected Behavior Now

### Test Alert (Should Work)
```
Simulated data has:
- gyro: 4.0-5.2 rad/s (well above 1.5)
- jerk: high values
- score: 70+

Result:  Triggers reliably
```

### Walking (Should NOT Trigger)
```
Walking motion has:
- gyro: 0.5-1.0 rad/s (below 1.5)
- jerk: 5-10 m/s³ (below 12.0)
- score: might reach 70+

Result:  Won't trigger (no evidence)
```

### Vigorous Shaking (Should Trigger)
```
Intentional shake has:
- gyro: 2.0-4.0 rad/s (above 1.5)
- jerk: 15-30 m/s³ (above 12.0)
- score: 70+

Result:  Triggers after 1.5s
```

## Summary

**Fixed:** Alert now requires BOTH high score AND violent motion evidence.

**Before:** Could trigger on high score alone (false positives)

**After:** Requires sustained violent motion (more reliable)

**Test it:** Run the app and check console logs for the new detailed output.

## Verification

After running the app, you should see:

 No more "Score high but weak evidence" in reasons  
 Count only increments when evidence present  
 Detailed logs showing gyro/jerk values  
 Clear indication when evidence found vs not found  
 More reliable triggering (fewer false positives)  
