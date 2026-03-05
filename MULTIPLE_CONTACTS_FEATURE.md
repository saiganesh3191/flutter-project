# Multiple Contacts Feature - AegisAI

##  Feature Complete!

I've updated your AegisAI system to support **5 contact slots** with **automatic alerts to top 3 contacts**!

---

## What Changed

### Backend Changes:

1.  **Database Model Updated**
   - Added `priority` field to TrustedContact (1-5)
   - Each device can have up to 5 contacts
   - Contacts ordered by priority

2.  **API Updated**
   - POST `/api/v1/contacts/` now accepts `priority` parameter
   - GET `/api/v1/contacts/` returns contacts with priority
   - POST `/api/v1/alerts/` now sends to top 3 contacts automatically

3.  **Alert Logic Updated**
   - Backend automatically fetches top 3 priority contacts
   - Sends WhatsApp/SMS to each contact
   - Returns count of successful sends

### Flutter App Changes:

1.  **Onboarding Screen Redesigned**
   - Now shows 5 contact input fields
   - Each contact has priority indicator (1-5)
   - Top 3 contacts marked as "Will receive alerts"
   - Visual priority badges (red for top 3, grey for 4-5)

2.  **Alert Manager Updated**
   - New method: `syncContactWithPriority(name, phone, priority)`
   - Alert sending simplified (backend handles top 3)
   - No need to specify contact in alert call

---

## How It Works

### Setup (Onboarding):
1. User opens app for first time
2. Sees 5 contact slots with priority labels:
   - Priority 1: Primary Contact (red badge)
   - Priority 2: Secondary Contact (red badge)
   - Priority 3: Third Contact (red badge)
   - Priority 4: Fourth Contact (grey badge)
   - Priority 5: Fifth Contact (grey badge)
3. User fills in at least 1 contact (can fill all 5)
4. Contacts saved to backend with priority

### Alert Sending:
1. High risk detected (score > 80)
2. Alert popup appears with countdown
3. If user doesn't click "I Am Safe":
   - App calls backend API
   - Backend fetches top 3 priority contacts
   - Backend sends WhatsApp/SMS to each contact
   - All 3 contacts receive alert simultaneously

---

## Database Migration

Already completed! 

```bash
python manage.py makemigrations
python manage.py migrate
```

---

## Testing Instructions

### Step 1: Restart Backend

```bash
cd django_backend
python manage.py runserver 0.0.0.0:8000
```

### Step 2: Clear App Data (Fresh Start)

On your Android phone:
1. Settings → Apps → AegisAI
2. Storage → Clear Data
3. This will show onboarding screen again

### Step 3: Run Flutter App

```bash
cd aegis_app
flutter run
```

Select device: I2012 (wireless)

### Step 4: Fill in 5 Contacts

On onboarding screen, add contacts:
- Priority 1: SiriChandana, +91 93476 88730
- Priority 2: Contact2 Name, +91 XXXXXXXXXX
- Priority 3: Contact3 Name, +91 XXXXXXXXXX
- Priority 4: (optional)
- Priority 5: (optional)

Click "Save & Continue"

### Step 5: Trigger Alert

Shake phone or wait for risk increase

### Step 6: Check Backend Logs

You should see:
```
 Sending alert to contact 1: SiriChandana (+919347688730)
 Sending WhatsApp message...
 WhatsApp message sent successfully!

 Sending alert to contact 2: Contact2 Name (+91XXXXXXXXXX)
 Sending WhatsApp message...
 WhatsApp message sent successfully!

 Sending alert to contact 3: Contact3 Name (+91XXXXXXXXXX)
 Sending WhatsApp message...
 WhatsApp message sent successfully!

Alert sent to 3 of 3 contacts
```

### Step 7: Verify Delivery

All 3 contacts should receive WhatsApp/SMS with:
```
 *AegisAI Emergency Alert*

From: [Contact Name]
Alert: High risk detected

 Location: https://www.google.com/maps?q=17.45,78.39

Triggered: timer
Time: 2026-03-01 13:30:45
```

---

## API Changes

### POST /api/v1/contacts/

**Request:**
```json
{
  "device_token": "xxx",
  "name": "John Doe",
  "phone": "+919876543210",
  "priority": 1
}
```

**Response:**
```json
{
  "message": "Contact saved"
}
```

### GET /api/v1/contacts/?device_token=xxx

**Response:**
```json
[
  {
    "name": "SiriChandana",
    "phone": "+919347688730",
    "priority": 1
  },
  {
    "name": "Contact2",
    "phone": "+91XXXXXXXXXX",
    "priority": 2
  },
  {
    "name": "Contact3",
    "phone": "+91XXXXXXXXXX",
    "priority": 3
  }
]
```

### POST /api/v1/alerts/

**Request:**
```json
{
  "device_token": "xxx",
  "lat": 17.4509422,
  "lng": 78.3949475,
  "message": "High risk detected",
  "triggered_by": "timer"
}
```

**Response:**
```json
{
  "message": "Alert sent to 3 of 3 contacts",
  "sent_count": 3,
  "total_contacts": 3
}
```

---

## Features

 **5 Contact Slots** - Add up to 5 trusted contacts
 **Priority System** - Contacts ranked 1-5
 **Top 3 Alerts** - Automatic alerts to top 3 priority contacts
 **Visual Indicators** - Red badges for top 3, grey for 4-5
 **Simultaneous Sending** - All 3 contacts receive alert at same time
 **WhatsApp + SMS** - Tries WhatsApp first, falls back to SMS
 **Delivery Tracking** - Backend logs success/failure for each contact

---

## Benefits

1. **Redundancy** - If one contact doesn't respond, 2 others are notified
2. **Flexibility** - User can add backup contacts (4-5) for future use
3. **Priority Control** - User decides who gets alerted first
4. **Reliability** - Multiple contacts = higher chance of help

---

## UI Preview

### Onboarding Screen:
```

  Add up to 5 trusted contacts       
  Top 3 will receive emergency alerts

   Primary Contact                
  1 Will receive alerts             
   Name: [____________]            
      Phone: [____________]           

   Secondary Contact              
  2 Will receive alerts             
   Name: [____________]            
      Phone: [____________]           

   Third Contact                  
  3 Will receive alerts             
   Name: [____________]            
      Phone: [____________]           

   Fourth Contact                 
  4                                 
   Name: [____________]            
      Phone: [____________]           

   Fifth Contact                  
  5                                 
   Name: [____________]            
      Phone: [____________]           

      [Save & Continue]               

```

---

## Summary

Your AegisAI system now:
-  Supports 5 contact slots with priority
-  Automatically sends alerts to top 3 contacts
-  Works with WhatsApp and SMS
-  Provides redundancy and reliability
-  Ready for testing!

**Test it now and let me know how it works!** 
