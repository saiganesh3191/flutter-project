# WhatsApp Integration Setup Guide - AegisAI

##  Backend Code Updated!

I've integrated WhatsApp automatic messaging into your backend. Now follow these steps to activate it:

---

## Step 1: Create Twilio Account (5 minutes)

### 1.1 Sign Up
1. Go to: https://www.twilio.com/try-twilio
2. Click "Sign up"
3. Fill in:
   - Email
   - Password
   - First name, Last name
4. Verify your email
5. Verify your phone number (+91 93476 88730)

### 1.2 Get Free Credits
- You'll receive **$15 USD free trial credits** (~₹1200)
- This gives you approximately **1000 free WhatsApp messages**!

---

## Step 2: Setup WhatsApp Sandbox (2 minutes)

### 2.1 Access WhatsApp Sandbox
1. Login to Twilio Console: https://console.twilio.com/
2. Click on **"Messaging"** in left sidebar
3. Click on **"Try it out"** → **"Send a WhatsApp message"**
4. You'll see the WhatsApp Sandbox page

### 2.2 Note Down Sandbox Details
You'll see:
- **Sandbox Number**: Something like `+1 415 523 8886`
- **Join Code**: Something like `join <your-code>`

**Copy both!**

### 2.3 Join the Sandbox
1. Open WhatsApp on phone +91 93476 88730
2. Send a message to the **Sandbox Number** (e.g., +1 415 523 8886)
3. Message content: The **Join Code** (e.g., `join abc-def`)
4. You'll receive a confirmation message from Twilio

**This activates WhatsApp for that number!**

---

## Step 3: Get API Credentials (1 minute)

### 3.1 Find Your Credentials
1. Go to Twilio Console: https://console.twilio.com/
2. On the main dashboard, you'll see:
   - **Account SID**: Starts with `AC...` (e.g., `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)
   - **Auth Token**: Click "Show" to reveal (e.g., `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)

### 3.2 Copy Both Values
- Account SID
- Auth Token

---

## Step 4: Update Backend Configuration (2 minutes)

### 4.1 Edit `.env` File

Open `django_backend/.env` and update these lines:

```env
# Twilio WhatsApp (Free automatic messaging)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_WHATSAPP_NUMBER=+14155238886
ENABLE_WHATSAPP=True

# MSG91 (SMS fallback - keep as backup)
ENABLE_MSG91_SMS=False
```

**Replace:**
- `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` with your Account SID
- `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` with your Auth Token
- `+14155238886` with your Sandbox Number

**Set:**
- `ENABLE_WHATSAPP=True` (enable WhatsApp)
- `ENABLE_MSG91_SMS=False` (disable SMS for now)

---

## Step 5: Install Twilio Library (1 minute)

### 5.1 Install Package

In your terminal:

```bash
cd django_backend
pip install twilio
```

### 5.2 Update requirements.txt

```bash
pip freeze > requirements.txt
```

---

## Step 6: Test It! (2 minutes)

### 6.1 Restart Django Backend

```bash
cd django_backend
python manage.py runserver 0.0.0.0:8000
```

### 6.2 Trigger Alert from Flutter App

1. Open Flutter app on phone
2. Shake phone or wait for risk increase
3. Let countdown complete

### 6.3 Check Backend Logs

You should see:
```
 Sending WhatsApp message
   From: whatsapp:+14155238886
   To: whatsapp:+919347688730
   Message:  *AegisAI Emergency Alert*...
 WhatsApp message sent successfully!
   Message SID: SMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   Status: queued
```

### 6.4 Check WhatsApp on Phone

Within seconds, you should receive a WhatsApp message:
```
 *AegisAI Emergency Alert*

Alert: High risk detected

 Location: https://www.google.com/maps?q=17.45,78.39

Triggered: timer
Time: 2026-03-01 12:30:45
```

---

## How It Works

### Message Flow:
1. Flutter app detects high risk
2. Shows alert popup with countdown
3. If user doesn't click "I Am Safe":
   - App calls backend API
   - Backend tries WhatsApp first (free, reliable)
   - If WhatsApp fails, falls back to MSG91 SMS
   - Contact receives WhatsApp message with location

### Priority Order:
1. **WhatsApp** (primary, free, automatic)
2. **MSG91 SMS** (fallback, paid, automatic)

---

## Advantages of WhatsApp

 **Free**: 1000 messages with trial credits
 **Automatic**: No user interaction needed
 **Reliable**: 95%+ delivery rate
 **Rich formatting**: Bold text, emojis, links
 **Read receipts**: Know when message is seen
 **Location links**: Clickable Google Maps links
 **No DLT**: No business registration needed
 **Instant**: Delivered within seconds

---

## Important Notes

### Sandbox Limitations:
-  Recipients must "join" the sandbox first (send join code)
-  For production, you need to apply for WhatsApp Business API approval
-  Sandbox is perfect for testing and demo

### For Production (Later):
1. Apply for WhatsApp Business API approval
2. Get your own WhatsApp Business number
3. No "join" requirement for recipients
4. Unlimited messages

---

## Troubleshooting

### "Recipient not joined sandbox"
- Make sure +91 93476 88730 sent the join code to sandbox number
- Check WhatsApp for confirmation message

### "Authentication failed"
- Double-check Account SID and Auth Token in `.env`
- Make sure no extra spaces or quotes

### "Invalid phone number"
- Phone must include country code: +919347688730
- No spaces or dashes

### WhatsApp not received
- Check backend logs for errors
- Verify recipient joined sandbox
- Check Twilio console logs: https://console.twilio.com/monitor/logs/messages

---

## Cost Breakdown

### Trial Credits ($15 USD):
- WhatsApp messages: ~1000 messages
- After trial: $0.005/message (₹0.40/message)

### Comparison:
- MSG91 SMS: ₹0.25/message (with DLT)
- WhatsApp: ₹0.40/message (after trial)
- **But**: WhatsApp has higher delivery rate and better features!

---

## Next Steps

1.  Create Twilio account
2.  Setup WhatsApp sandbox
3.  Get API credentials
4.  Update `.env` file
5.  Install twilio package
6.  Test from Flutter app
7.  Verify WhatsApp delivery

---

## Summary

Your AegisAI system now supports:
-  **WhatsApp** (primary, free, automatic)
-  **MSG91 SMS** (fallback, paid, automatic)
-  **Hybrid approach** (tries WhatsApp first, falls back to SMS)

**Total setup time: ~15 minutes**
**Cost: Free (1000 messages with trial)**

---

**Ready to test? Follow the steps above and let me know if you need help!**
