# Contact Push Notification Fix

## Problem
Contact device is NOT receiving push notifications when admin triggers an alert, even though the contact has the AegisAI app installed.

## Root Cause
The contact is NOT linked to their device in the backend database. The `contact_device` field in the TrustedContact model is NULL.

**Why?** Contact linking happens when contacts are saved. After backend restart, contacts need to be re-saved to trigger the linking logic.

## Backend Logs Analysis

### Current Logs (Contact NOT Linked):
```
 Sending push notification to device 01a196d9-753b-4018-81a8-cc78c476252f (admin device)
 Push notification sent successfully
 Sending alert to contact 1: sukanya (+91 62811 90183)
 Sending WhatsApp message
 WhatsApp message sent successfully!
```

**Missing:** " Contact has AegisAI app! Sending push notification..."

### Expected Logs (Contact Linked):
```
 Contact sukanya (+91 62811 90183) has the app! Linked device <device_id> (+916281190183)
```

## Solution: Re-Link Contacts

### Step 1: Re-Save Contacts on Admin Device
1. Open the **Admin device** (emulator)
2. Click the **Settings** icon (gear icon in top-right)
3. Select **"Manage Contacts"**
4. The contacts should already be filled in
5. Click **"Save & Continue"**

### Step 2: Verify Linking in Backend Logs
Watch the backend terminal. You should see:
```
 Phone number updated for device <device_id>: +919989456787
 Deleted X contacts for device <device_id>
 Contact sukanya (+91 62811 90183) has the app! Linked device <device_id> (+916281190183)
```

### Step 3: Test Alert Again
1. On Admin device, trigger the alert (Test High Risk button)
2. Backend logs should now show:
```
 Sending push notification to device <admin_device_id>
 Push notification sent successfully
 Sending alert to contact 1: sukanya (+91 62811 90183)
 Contact has AegisAI app! Sending push notification...
 Sending push notification to device <contact_device_id>
 Push notification sent successfully
 Sending WhatsApp message
 WhatsApp message sent successfully!
```

3. **Contact device should receive push notification!**

## How Contact Linking Works

### Backend Logic (in `create_contact` view):
```python
# Get just digits from contact phone
contact_digits = ''.join(filter(str.isdigit, contact.phone))

# Check all devices to find matching phone
all_devices = Device.objects.filter(phone_number__isnull=False)
for device in all_devices:
    device_digits = ''.join(filter(str.isdigit, device.phone_number))
    # Match last 10 digits (handles country code variations)
    if contact_digits[-10:] == device_digits[-10:]:
        contact.contact_device = device
        contact.save()
        print(f' Contact {contact.name} ({contact.phone}) has the app! Linked device {device.device_id}')
        break
```

### Requirements for Linking:
1.  Contact device must be registered with phone number
2.  Contact phone number must match device phone number (last 10 digits)
3.  Contact must be saved AFTER device registration

## Logout Feature

Both Admin and Contact interfaces now have logout functionality:

### Admin Interface:
- Click **Settings** icon (gear) → **Logout**
- Stops monitoring, clears all data, returns to login screen

### Contact Interface:
- Click **Logout** icon (top-right)
- Clears all data, returns to login screen

## Troubleshooting

### If Contact Still Doesn't Receive Notification:

1. **Verify Contact Device Registration:**
   - Contact device logs should show: `Device registered successfully with phone: <phone>`

2. **Verify Phone Numbers Match:**
   - Admin saves contact: `+91 62811 90183`
   - Contact device registered: `+916281190183` or `6281190183`
   - Last 10 digits must match: `6281190183`

3. **Verify FCM Token:**
   - Contact device logs should show: ` FCM token sent to backend`
   - Backend should have FCM token for contact device

4. **Check Backend Database:**
   ```bash
   python manage.py shell
   ```
   ```python
   from api.models import Device, TrustedContact
   
   # Check contact device
   contact = TrustedContact.objects.get(name='sukanya')
   print(f"Contact: {contact.name} ({contact.phone})")
   print(f"Linked device: {contact.contact_device}")
   
   # Check device phone
   if contact.contact_device:
       print(f"Device phone: {contact.contact_device.phone_number}")
       print(f"FCM token: {contact.contact_device.fcm_token[:20]}...")
   ```

## Summary

The fix is simple: **Re-save contacts on Admin device** to trigger the linking logic. This will connect the contact's phone number to their device, enabling push notifications.

After re-saving, the contact device will receive:
-  Push notification (instant)
-  WhatsApp message (backup)
-  SMS (if configured)
