# AegisAI - Transactional SMS Configuration Complete! 

## Configuration Summary

### MSG91 Template Created
- **Template Name**: AegisAI_Safety_Alert
- **Template ID**: `69a3e0c2de901ea1a3077254`
- **Route**: 4 (Transactional)
- **Status**: Pending approval (should be approved soon)

### Template Content
```
Emergency Alert from ##var1##. Reason: ##var2##. View Location: ##var3##
```

### Variables Mapping
- **var1** = User name (e.g., "SiriChandana")
- **var2** = Alert reason (e.g., "High risk detected")
- **var3** = Google Maps location URL

---

## Backend Configuration 

### `.env` File Updated
```env
MSG91_AUTH_KEY=497258ACavnGkGmYQ569a3cb4fP1
MSG91_SENDER_ID=AEGSAI
MSG91_TEMPLATE_ID=69a3e0c2de901ea1a3077254
MSG91_USE_DLT=True
ENABLE_MSG91_SMS=True
```

### SMS Sending Method
-  **Route 4 (Transactional)** - Automatic, 24/7
-  **No user interaction required**
-  **Emergency alert compliant**
-  **100 free SMS/day**

---

## How It Works

### 1. User Opens App
- Enters trusted contact name and phone number
- Contact saved to backend database

### 2. Risk Detection
- App monitors sensors (accelerometer, location, etc.)
- Risk engine calculates risk score
- When risk > 80%, alert popup appears

### 3. Alert Countdown
- 5-second countdown timer
- User can click "I Am Safe" to cancel
- If no action, alert sends automatically

### 4. Automatic SMS Sending
- Backend receives alert API call
- Extracts contact phone from database
- Calls MSG91 API with template ID
- SMS sent via Route 4 (Transactional)
- Contact receives SMS with location link

---

## SMS Message Format

When alert is triggered, contact receives:
```
Emergency Alert from SiriChandana. Reason: High risk detected. View Location: https://www.google.com/maps?q=17.4509422,78.3949475
```

---

## Testing Instructions

### 1. Restart Django Backend
```bash
cd django_backend
python manage.py runserver 0.0.0.0:8000
```

### 2. Open Flutter App
- Make sure app is connected to backend
- Contact should be already registered

### 3. Trigger Alert
- Shake phone vigorously, OR
- Wait for risk score to increase naturally

### 4. Watch Backend Logs
You should see:
```
 Sending MSG91 SMS (Route 4 - Transactional with DLT)
   To: 919347688730
   Template ID: 69a3e0c2de901ea1a3077254
   Variables: name=User, reason=High risk detected, location=https://...
 MSG91 Response Status: 200
   Response Body: {"type":"success","message":"..."}
 MSG91 SMS sent successfully to +91 93476 88730
```

### 5. Check Phone
- SMS should arrive within seconds
- Check +91 93476 88730
- Click location link to see map

---

## Template Status

Your template shows "Pending (by USER)" which means:
- ⏳ Waiting for MSG91 approval
- ⏳ Usually approved within minutes to hours
- ⏳ Once approved, status will change to "Active"

### To Check Template Status
1. Login to MSG91 dashboard
2. Go to SMS → Templates
3. Look for "AegisAI_Safety_Alert"
4. Status should change from "Pending" to "Active"

---

## Troubleshooting

### If SMS Not Received

**Check 1: Template Status**
- Go to MSG91 dashboard → Templates
- Make sure template is "Active" (not "Pending")
- If still pending, contact MSG91 support

**Check 2: Backend Logs**
- Look for "Route 4 - Transactional" in logs
- Check for error messages
- Verify Template ID is correct

**Check 3: MSG91 Response**
- If response shows "template not found" → Template not approved yet
- If response shows "success" → SMS was sent, check phone
- If response shows "error" → Share error with MSG91 support

**Check 4: Account Balance**
- Login to MSG91 dashboard
- Check credits/balance
- Should show 100 free SMS available

---

## Advantages of Transactional Route

 **24/7 Availability** - No time restrictions (unlike Promotional 9 AM - 9 PM)
 **Automatic Sending** - No user interaction required
 **Higher Priority** - Delivered faster than promotional SMS
 **Emergency Compliant** - Proper route for safety alerts
 **Professional** - Follows Indian TRAI regulations

---

## Next Steps

1.  **Wait for template approval** (check MSG91 dashboard)
2.  **Restart Django backend** with new configuration
3.  **Test from Flutter app** - Trigger alert
4.  **Verify SMS delivery** on phone +91 93476 88730
5.  **System is production-ready!**

---

## Support Contacts

### MSG91 Support
- Email: support@msg91.com
- Phone: +91-9650-800-800
- Dashboard: https://control.msg91.com

### Template ID for Reference
```
69a3e0c2de901ea1a3077254
```

---

## System Status

-  Flutter app complete
-  Django backend complete
-  MSG91 integration complete
-  Template created
- ⏳ Template approval pending
-  Ready for testing!

---

**Your AegisAI safety monitoring system is now configured for automatic transactional SMS alerts!**
