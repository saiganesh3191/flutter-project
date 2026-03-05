# MSG91 SMS Setup Guide - AegisAI

## Current Status 
- Auth Key: `497258ACavnGkGmYQ569a3cb4fP1`
- Sender ID: `AEGSAI`
- KYC: Approved
- Free SMS: 100/day

## Why You're Getting Test SMS

MSG91 sends test SMS in these cases:
1. **Account in Test Mode** - New accounts start in test mode
2. **Time Restrictions** - Route 1 (Promotional) only works 9 AM - 9 PM IST
3. **DLT Template Missing** - For Route 4 (Transactional), you need DLT template

## Solution: Check Account Status

### Step 1: Login to MSG91 Dashboard
1. Go to: https://control.msbro i bpi iag91.com/signin/
2. Login with your credentials

### Step 2: Check Account Mode
1. Look for "Test Mode" or "Live Mode" indicator
2. If in Test Mode, you need to:
   - Complete KYC (already done )
   - Add credits OR wait for activation
   - Contact support to enable Live Mode

### Step 3: Check Current Time
- Route 1 (Promotional) only works: **9 AM - 9 PM IST**
- Current time: Check if within allowed hours
- If outside hours, SMS will be queued or rejected

### Step 4: Verify Free SMS Balance
1. In MSG91 dashboard, check "Credits" or "Balance"
2. You should see "100 Free SMS" or similar
3. If balance is 0, contact MSG91 support

## Testing Right Now

### Option A: Wait for Business Hours
- Test between 9 AM - 9 PM IST
- Route 1 (Promotional) will work

### Option B: Use Route 4 (Transactional) - 24/7
1. Create DLT Template in MSG91 dashboard:
   - Go to: SMS → DLT Templates
   - Click "Add Template"
   - Template: `Alert from ##var1## Location: ##var2##`
   - Get Template ID (e.g., `1234567890123456789`)

2. Update `.env` file:
   ```
   MSG91_TEMPLATE_ID=your_template_id_here
   ```

3. I'll update the code to use Route 4 with template

## Quick Test Command

Run this in your Django backend terminal:
```bash
python manage.py shell
```

Then paste:
```python
import requests

url = "https://control.msg91.com/api/sendhttp.php"
params = {
    "authkey": "497258ACavnGkGmYQ569a3cb4fP1",
    "mobiles": "919347688730",
    "message": "Test from AegisAI - Real SMS",
    "sender": "AEGSAI",
    "route": "1",
    "country": "91",
}

response = requests.get(url, params=params)
print(f"Status: {response.status_code}")
print(f"Response: {response.text}")
```

## Expected Responses

### Success (Real SMS):
```
Status: 200
Response: 5dXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX (32-char hex)
```

### Test Mode:
```
Status: 200
Response: Message sent in test mode
```

### Time Restriction:
```
Status: 200
Response: {"message":"promotional sms can be sent between 9AM to 9PM","type":"error"}
```

### No Credits:
```
Status: 200
Response: {"message":"Insufficient credits","type":"error"}
```

## Next Steps

1. **Check current time** - Is it between 9 AM - 9 PM IST?
2. **Login to MSG91** - Verify account is in Live Mode
3. **Check balance** - Confirm 100 free SMS available
4. **Test again** - Trigger alert from app
5. **If still test SMS** - Contact MSG91 support with your Auth Key

## Contact MSG91 Support

If still getting test SMS after checking above:
- Email: support@msg91.com
- Phone: +91-9650-800-800
- Tell them: "KYC approved but still receiving test SMS, please activate live mode"
- Provide your Auth Key: `497258ACavnGkGmYQ569a3cb4fP1`

## Current Backend Configuration

The backend is now using MSG91 v5 API with better error handling. It will:
-  Send SMS via Route 1 (Promotional, 9 AM - 9 PM)
-  Show detailed logs in Django console
-  Handle test mode gracefully
-  Work with 100 free SMS/day

## Testing Now

1. Make sure Django backend is running:
   ```bash
   cd django_backend
   python manage.py runserver 0.0.0.0:8000
   ```

2. Trigger alert from Flutter app

3. Check Django console for detailed logs

4. Check phone for SMS (if within 9 AM - 9 PM IST)
