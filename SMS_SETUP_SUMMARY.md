# AegisAI SMS Setup - Quick Summary

## Current Status

 Backend configured with MSG91 (100 free SMS/day)
 Supports both Route 1 and Route 4
 KYC approved
 Auth Key configured

## Two Options for SMS

### Option 1: Route 1 (Promotional) - CURRENT DEFAULT 

**Pros**:
- No DLT template needed
- Works immediately
- Simple setup

**Cons**:
- Only works 9 AM - 9 PM IST
- May send test SMS if account not activated

**Configuration** (already set):
```env
MSG91_USE_DLT=False
```

**To test**: Trigger alert between 9 AM - 9 PM IST

---

### Option 2: Route 4 (Transactional) - RECOMMENDED FOR PRODUCTION 

**Pros**:
- Works 24/7 (no time restrictions)
- Real SMS content (not test)
- Professional and compliant

**Cons**:
- Requires DLT template setup (5 minutes)

**Setup Steps**:

1. **Create DLT Template** in MSG91 dashboard:
   - Login: https://control.msg91.com/signin/
   - Go to: SMS → DLT Templates → Add Template
   - Template: `Alert from ##var1##. Reason: ##var2##. Location: ##var3##`
   - Copy Template ID (19-digit number)

2. **Update `.env`**:
   ```env
   MSG91_TEMPLATE_ID=your_template_id_here
   MSG91_USE_DLT=True
   ```

3. **Restart backend**:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

4. **Test from app** - SMS will work 24/7!

---

## Quick Test Right Now

### If it's between 9 AM - 9 PM IST:

1. Make sure Django backend is running:
   ```bash
   cd django_backend
   python manage.py runserver 0.0.0.0:8000
   ```

2. Open Flutter app on phone

3. Trigger alert (shake phone or wait for timer)

4. Check Django console - you should see:
   ```
    Sending MSG91 SMS (Route 1 - Promotional)
    MSG91 Response Status: 200
    MSG91 SMS sent successfully
   ```

5. Check phone for SMS!

### If it's outside 9 AM - 9 PM IST:

You'll see this error:
```
 Error: promotional sms can be sent between 9AM to 9PM
```

**Solution**: Either wait until 9 AM, or set up Route 4 (DLT template)

---

## Files Changed

1. `django_backend/.env` - Added DLT configuration
2. `django_backend/aegisai/settings.py` - Added DLT settings
3. `django_backend/api/views.py` - Added dual-mode SMS support

---

## What Happens When You Trigger Alert

1. Flutter app detects high risk
2. Shows alert popup with 5-second countdown
3. If user doesn't click "I Am Safe":
   - App calls backend API: `POST /api/v1/alerts/`
   - Backend logs alert to database
   - Backend sends SMS via MSG91
   - SMS arrives on contact's phone with location link
4. User sees "Alert Sent" screen

---

## Logs to Watch

In Django console, you'll see:
```
 Sending MSG91 SMS (Route 1 - Promotional)
   To: 919347688730
   Message: High risk detected Location: https://www.google.com/maps?q=17.45,78.39
 MSG91 Response Status: 200
   Response Body: 3663616b6257746349774d51
 MSG91 SMS sent successfully to +91 93476 88730
```

---

## Troubleshooting

### "Test SMS" received instead of real content
- **Cause**: Account in test mode or outside 9 AM - 9 PM
- **Fix**: Set up Route 4 with DLT template (see Option 2 above)

### No SMS received at all
- **Check 1**: Is it between 9 AM - 9 PM IST?
- **Check 2**: Django console shows success?
- **Check 3**: Phone number correct? (+91 93476 88730)
- **Check 4**: MSG91 balance > 0?

### "Template ID missing" error
- **Cause**: Using Route 4 without template
- **Fix**: Either create DLT template OR set `MSG91_USE_DLT=False`

---

## Recommendation

**For demo/testing**: Use Route 1 (current setup), test between 9 AM - 9 PM

**For production**: Set up Route 4 with DLT template (5 minutes), works 24/7

---

## Need Help?

1. Read: `DLT_TEMPLATE_SETUP.md` for detailed Route 4 setup
2. Read: `MSG91_SETUP_GUIDE.md` for troubleshooting
3. Share Django console logs if issues persist
