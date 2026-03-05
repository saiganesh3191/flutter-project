# MSG91 DLT Template Setup - Route 4 (24/7 SMS)

## Why Use Route 4 with DLT?

-  **24/7 SMS sending** (no time restrictions)
-  **Real SMS content** (not test messages)
-  **Professional** (compliant with Indian TRAI regulations)
-  **Still FREE** (100 SMS/day)

## Step-by-Step Setup

### Step 1: Login to MSG91 Dashboard

1. Go to: https://control.msg91.com/signin/
2. Login with your credentials
3. You should see your dashboard

### Step 2: Navigate to DLT Templates

1. Click on **"SMS"** in the left menu
2. Click on **"DLT Templates"** or **"Templates"**
3. Click **"Add Template"** or **"Create New Template"** button

### Step 3: Create Template

Fill in the form:

**Template Name**: 
```
AegisAI Safety Alert
```

**Template Type**: 
```
Transactional
```

**Template Content** (copy exactly):
```
Alert from ##var1##. Reason: ##var2##. Location: ##var3##
```

**Variables**:
- var1 = User name
- var2 = Alert reason (e.g., "High risk detected")
- var3 = Google Maps location URL

**Category**: 
```
Alert/Notification
```

### Step 4: Submit and Get Template ID

1. Click **"Submit"** or **"Create Template"**
2. Wait for approval (usually instant for transactional)
3. Once approved, you'll see a **Template ID** (long number like `1234567890123456789`)
4. **COPY THIS TEMPLATE ID** - you'll need it!

### Step 5: Update Backend Configuration

Open `django_backend/.env` and update:

```env
# MSG91 Configuration
MSG91_AUTH_KEY=497258ACavnGkGmYQ569a3cb4fP1
MSG91_SENDER_ID=AEGSAI
MSG91_TEMPLATE_ID=YOUR_TEMPLATE_ID_HERE
MSG91_USE_DLT=True
ENABLE_MSG91_SMS=True
```

Replace `YOUR_TEMPLATE_ID_HERE` with the Template ID you copied.

### Step 6: Restart Django Backend

```bash
# Stop the current server (Ctrl+C)
# Then restart:
cd django_backend
python manage.py runserver 0.0.0.0:8000
```

### Step 7: Test!

1. Open your Flutter app on the phone
2. Trigger an alert (shake phone or wait for timer)
3. Check Django console for logs
4. Check phone for SMS (should arrive within seconds)

## Example Template IDs

Template IDs look like this:
- `1234567890123456789` (19 digits)
- `6789012345678901234` (19 digits)

## Troubleshooting

### "Template not found" error
- Double-check Template ID in `.env` file
- Make sure template is approved in MSG91 dashboard
- No spaces or quotes around Template ID

### "DLT not registered" error
- Your sender ID (AEGSAI) needs DLT registration
- Contact MSG91 support to register sender ID
- Or use default sender ID provided by MSG91

### Still getting test SMS
- Make sure `MSG91_USE_DLT=True` in `.env`
- Restart Django backend after changing `.env`
- Check Django console logs for "Route 4 - Transactional"

## Alternative: Keep Using Route 1 (Promotional)

If you don't want to set up DLT template, you can keep using Route 1:

In `django_backend/.env`:
```env
MSG91_USE_DLT=False
```

**Limitations**:
- Only works 9 AM - 9 PM IST
- May send test SMS if account not fully activated

## Current Configuration

Right now, your backend supports BOTH modes:

1. **Route 1 (Promotional)** - Default, no DLT needed
   - Set `MSG91_USE_DLT=False`
   - Works 9 AM - 9 PM IST only

2. **Route 4 (Transactional)** - With DLT template
   - Set `MSG91_USE_DLT=True`
   - Add `MSG91_TEMPLATE_ID=your_id`
   - Works 24/7

## Next Steps

1.  Create DLT template in MSG91 dashboard
2.  Copy Template ID
3.  Update `.env` file with Template ID
4.  Set `MSG91_USE_DLT=True`
5.  Restart Django backend
6.  Test from Flutter app
7.  Verify real SMS received!

## Need Help?

If you get stuck:
1. Share screenshot of MSG91 dashboard
2. Share Django console logs
3. I'll help you debug!
