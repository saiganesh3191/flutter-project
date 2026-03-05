#  TEST THE ALERT POPUP FIX NOW!

## What Was Fixed
 Lowered trigger thresholds (gyro: 3.2→1.5, jerk: 18→12)  
 Reduced required samples (20→8 samples = 3s→1.2s)  
 Reduced cooldown (5 min→10 sec for testing)  
 Added detailed debug logging to track count accumulation

## Run the App

```bash
cd aegis_app
flutter run
```

## Test Steps

### 1. Start Monitoring
- Open app
- Tap **"Start"** button
- Wait 2 seconds for sensors to initialize

### 2. Trigger Alert (Choose One)

**Option A: Test Button** (Easiest)
- Tap **"Test Alert"** button
- Watch console logs
- Popup should appear in ~1.2 seconds

**Option B: Real Shaking** (More realistic)
- Shake phone vigorously for 2 seconds
- Watch console logs
- Popup should appear

## What to Look For

### Console Logs (IMPORTANT!)
You should see logs like this:

```
 Trigger: score=71, isHigh=true, hasEvidence=true, gyro=2.34/1.5, jerk=15.67/12.0, count=3/8
 Count++ = 4

 Trigger: score=73, isHigh=true, hasEvidence=true, gyro=2.89/1.5, jerk=18.23/12.0, count=4/8
 Count++ = 5

 Trigger: score=75, isHigh=true, hasEvidence=true, gyro=3.12/1.5, jerk=20.45/12.0, count=7/8
 Count++ = 8

 ALERT TRIGGERED! count=8
```

### Alert Popup
- Should appear after count reaches 8
- Shows countdown timer (10 seconds)
- Has "I'm Safe" and "Send Alert" buttons

## If It Still Doesn't Work

Check the logs for:

1. **Count not increasing?**
   - Look for ` No evidence, count-- = X`
   - Means gyro/jerk too low
   - Shake harder or lower thresholds more

2. **Score not reaching 70?**
   - Look for `score=XX` in logs
   - If score < 70, shake more vigorously
   - Check risk engine config

3. **Popup appears but immediately?**
   - Check cooldown logs
   - Should wait 10 seconds between alerts

## Success Criteria

 Console shows count accumulating: 1→2→3→4→5→6→7→8  
 Console shows ` ALERT TRIGGERED!`  
 Popup appears on screen  
 Countdown timer starts (10 seconds)  
 Can tap "I'm Safe" to dismiss  
 Can tap "Send Alert" to send SMS/WhatsApp

## After Testing

If it works:
1. Increase thresholds for production (see ALERT_TRIGGER_FIX.md)
2. Increase cooldown to 5 minutes
3. Consider adding manual panic button as PRIMARY trigger

If it doesn't work:
1. Share the console logs
2. We'll tune thresholds further
