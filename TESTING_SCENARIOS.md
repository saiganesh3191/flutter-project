#  TESTING SCENARIOS - AEGISAI SAFETY SYSTEM

##  OBJECTIVE
Validate ZERO false positives while maintaining high true positive rate.

---

##  FALSE POSITIVE TESTS (Should NOT Trigger)

### Test 1: Walking
**Action**: Walk normally for 2 minutes
**Expected**: 
- Risk score stays < 40
- No alert arming
- Console shows "Periodic motion detected (walking/running)"

**Why It Works**:
- Periodicity detector identifies regular 1-2 Hz pattern
- Walking has predictable oscillations
- System suppresses score when periodicity detected

---

### Test 2: Running
**Action**: Run for 1 minute
**Expected**:
- Risk score may reach 40-60 (medium)
- No alert arming
- Console shows "Periodic motion detected (walking/running)"

**Why It Works**:
- Running has 2-3 Hz periodic pattern
- Higher frequency but still regular
- Periodicity filter catches it

---

### Test 3: Bus/Car Travel
**Action**: Ride in vehicle for 5 minutes
**Expected**:
- Risk score stays < 30
- No alert arming
- Console shows "Smooth acceleration detected (vehicle)"

**Why It Works**:
- Vehicle motion has low jerk (smooth)
- Acceleration is sustained, not chaotic
- Smooth acceleration filter catches it

---

### Test 4: Phone Vibration
**Action**: Receive call/notification while phone on table
**Expected**:
- Brief score spike to 20-30
- Immediate decay
- No alert arming

**Why It Works**:
- Short duration (< 1 second)
- Low variance filter catches steady vibration
- Requires sustained high score (10+ samples)

---

### Test 5: Dropping Phone
**Action**: Drop phone onto soft surface (bed/couch)
**Expected**:
- Score spike to 40-50
- Rapid decay
- No alert arming

**Why It Works**:
- Single impact, not sustained
- Requires 8-10 consecutive high samples
- One spike doesn't meet threshold

---

### Test 6: Gym Workout
**Action**: Do jumping jacks or burpees for 30 seconds
**Expected**:
- Score may reach 50-60
- No alert arming
- Console shows "Periodic motion detected" or "Low variance"

**Why It Works**:
- Exercises have repetitive patterns
- Periodicity detector catches regular movements
- Even if high score, evidence diversity requirement not met

---

### Test 7: Dancing
**Action**: Dance to music for 1 minute
**Expected**:
- Score fluctuates 30-50
- No alert arming
- Console shows "Periodic motion detected" or "Below statistical threshold"

**Why It Works**:
- Dancing has rhythmic patterns
- Not chaotic enough to trigger anomaly detection
- Lacks violent rotation + sudden jerk combination

---

### Test 8: Picking Up/Putting Down Phone
**Action**: Pick up phone, use it, put it down (repeat 10 times)
**Expected**:
- Brief score spikes to 20-40
- Rapid decay each time
- No alert arming

**Why It Works**:
- Orientation changes detected
- Short duration events
- Not sustained enough

---

##  TRUE POSITIVE TESTS (SHOULD Trigger)

### Test 9: Violent Shaking
**Action**: Shake phone violently in all directions for 2 seconds
**Expected**:
- Score rapidly climbs to 70+
- Alert arms within 1.2-1.5 seconds
- 8-second countdown appears
- Alert sends if not cancelled

**Why It Works**:
- High gyro magnitude (rotation)
- High jerk (sudden changes)
- Chaotic, non-periodic pattern
- Meets all evidence requirements

---

### Test 10: Simulated Struggle
**Action**: Hold phone and simulate struggle movements (rapid back-forth, rotation)
**Expected**:
- Score reaches 80+
- Alert arms within 1.5 seconds
- Countdown dialog shows
- Alert sends if not cancelled

**Why It Works**:
- Multiple evidence types (gyro + jerk)
- Sustained high score (10+ samples)
- Non-periodic, chaotic motion
- Statistical anomaly detected

---

### Test 11: Test Button (Simulated Data)
**Action**: Press "Test Alert" button
**Expected**:
- Score jumps to 90+
- Alert arms immediately
- Countdown shows
- Alert sends after 8 seconds

**Why It Works**:
- Simulated data bypasses filters
- Designed to always trigger
- Used for system validation

---

##  NIGHT MODE TESTS

### Test 12: Night Mode Activation
**Action**: Change device time to 11 PM, start monitoring
**Expected**:
- UI shows " Peak Night" mode
- "ENHANCED" badge visible
- Console shows "mult=1.50x"

**Why It Works**:
- Time-based mode detection
- 11 PM - 4 AM = peak night
- 1.5x score multiplier active

---

### Test 13: Night Mode Sensitivity
**Action**: At 11 PM, perform moderate shaking (less violent than Test 9)
**Expected**:
- Alert arms faster than daytime (8 samples vs 10)
- Lower thresholds (gyro 1.2 vs 1.5)
- Longer cooldown (60s vs 30s)

**Why It Works**:
- Dynamic thresholds based on time
- Night mode = more sensitive
- Prevents spam with longer cooldown

---

### Test 14: Day vs Night Comparison
**Action**: Same shaking motion at 2 PM and 2 AM
**Expected**:
- 2 PM: May not trigger (requires more evidence)
- 2 AM: Triggers faster (enhanced mode)

**Why It Works**:
- Time-aware risk assessment
- Night = statistically more dangerous
- System adapts to context

---

##  PERFORMANCE TESTS

### Test 15: Battery Drain
**Action**: Monitor for 1 hour with screen off
**Expected**:
- < 5% battery drain
- Background service running
- Foreground notification visible

**Measurement**:
- Check battery stats before/after
- Should be < 5% per hour

---

### Test 16: Processing Latency
**Action**: Trigger test alert, measure time to countdown
**Expected**:
- < 2 seconds from trigger to countdown dialog
- < 100ms per sample processing

**Measurement**:
- Console logs show timestamps
- " READY TO ARM" to dialog < 2s

---

### Test 17: Memory Usage
**Action**: Monitor for 30 minutes, check memory
**Expected**:
- < 100 MB RAM usage
- No memory leaks
- Stable over time

**Measurement**:
- Android Studio Profiler
- Memory should plateau, not climb

---

##  EDGE CASE TESTS

### Test 18: Rapid Start/Stop
**Action**: Start monitoring, stop, start, stop (repeat 10 times)
**Expected**:
- No crashes
- Clean state reset each time
- No lingering alerts

---

### Test 19: No Contacts
**Action**: Delete all contacts, trigger alert
**Expected**:
- Alert attempts to send
- Error logged: "No contacts found"
- No crash

---

### Test 20: No Location Permission
**Action**: Deny location, start monitoring
**Expected**:
- Monitoring works
- Location = 0.0, 0.0
- No crash

---

### Test 21: Airplane Mode
**Action**: Enable airplane mode, trigger alert
**Expected**:
- Alert attempts to send
- SMS fails gracefully
- Error logged, no crash

---

### Test 22: Low Battery
**Action**: Trigger alert at < 10% battery
**Expected**:
- Alert still sends
- System prioritizes safety over battery

---

##  SUCCESS CRITERIA

### False Positive Rate
-  Walking: 0%
-  Running: 0%
-  Vehicle: 0%
-  Phone handling: 0%
-  Gym: 0%
-  Dancing: 0%

### True Positive Rate
-  Violent shaking: 95%+
-  Simulated struggle: 95%+
-  Test button: 100%

### Performance
-  Detection time: < 2s
-  Processing latency: < 100ms
-  Battery drain: < 5%/hour
-  Memory usage: < 100 MB

---

##  HACKATHON DEMO SCRIPT

1. **Introduction** (30 seconds)
   - "AegisAI is a women's safety app with ZERO false positives"
   - "Uses advanced pattern recognition and statistical analysis"

2. **False Positive Demo** (2 minutes)
   - Walk around: "See? No false alarm"
   - Shake phone gently: "Still safe"
   - Drop phone: "One impact doesn't trigger"

3. **True Positive Demo** (1 minute)
   - Press test button: "Now watch this..."
   - Countdown appears: "8 seconds to cancel"
   - Show SMS sent: "Alert delivered via SMS + WhatsApp"

4. **Night Mode Demo** (1 minute)
   - Show time mode indicator
   - Explain dynamic thresholds
   - "More sensitive at night when danger is higher"

5. **Technical Deep Dive** (2 minutes)
   - Show console logs
   - Explain periodicity detection
   - Explain evidence diversity requirement
   - Show statistical anomaly detection

6. **Q&A** (remaining time)

---

**Total Test Time**: ~2 hours for complete validation
**Recommended**: Run all tests before hackathon presentation
**Critical**: Tests 1-8 (false positives) and 9-11 (true positives)
