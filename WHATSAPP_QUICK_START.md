# WhatsApp Integration - Quick Start (15 Minutes)

##  What I've Done

I've integrated WhatsApp automatic messaging into your AegisAI backend!

**Changes made:**
-  Added WhatsApp support to `django_backend/api/views.py`
-  Updated `django_backend/.env` configuration
-  Updated `django_backend/aegisai/settings.py`
-  Created setup guide and scripts

---

##  Quick Setup (Follow These Steps)

### Step 1: Install Twilio Library (30 seconds)

```bash
cd django_backend
pip install twilio
```

### Step 2: Create Twilio Account (3 minutes)

1. Go to: https://www.twilio.com/try-twilio
2. Sign up (free)
3. Verify your phone: +91 93476 88730
4. You get **$15 free credits** = ~1000 WhatsApp messages!

### Step 3: Setup WhatsApp Sandbox (2 minutes)

1. Login to: https://console.twilio.com/
2. Go to: **Messaging** → **Try it out** → **Send a WhatsApp message**
3. You'll see:
   - Sandbox Number (e.g., `+1 415 523 8886`)
   - Join Code (e.g., `join abc-def`)
4. **Send the join code** from +91 93476 88730 to the sandbox number via WhatsApp

### Step 4: Get API Credentials (1 minute)

On Twilio dashboard, copy:
- **Account SID**: `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
- **Auth Token**: Click "Show" to reveal

### Step 5: Update `.env` File (1 minute)

Edit `django_backend/.env`:

```env
# Twilio WhatsApp
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_WHATSAPP_NUMBER=+14155238886
ENABLE_WHATSAPP=True

# Disable MSG91 for now (use WhatsApp instead)
ENABLE_MSG91_SMS=False
```

Replace with your actual values!

### Step 6: Restart Backend (30 seconds)

```bash
cd django_backend
python manage.py runserver 0.0.0.0:8000
```

### Step 7: Test! (1 minute)

1. Open Flutter app
2. Trigger alert (shake phone)
3. Check WhatsApp on +91 93476 88730
4. You should receive: " *AegisAI Emergency Alert*..."

---

##  What You'll Get

### WhatsApp Message Format:
```
 *AegisAI Emergency Alert*

Alert: High risk detected

 Location: https://www.google.com/maps?q=17.45,78.39

Triggered: timer
Time: 2026-03-01 12:30:45
```

### Features:
-  Automatic (no user interaction)
-  Free (1000 messages)
-  Rich formatting (bold, emojis)
-  Clickable location link
-  Read receipts
-  Instant delivery

---

##  Why WhatsApp is Better Than SMS

| Feature | WhatsApp | SMS |
|---------|----------|-----|
| Cost | Free (1000 msgs) | ₹0.25/msg |
| Delivery Rate | 95%+ | 70% |
| Read Receipts |  Yes |  No |
| Rich Formatting |  Yes |  No |
| DLT Required |  No |  Yes |
| Setup Time | 15 min | 3-5 days |
| Business Docs |  No |  Yes |

---

##  Backend Logic

Your backend now works like this:

```
Alert Triggered
    ↓
Try WhatsApp First (free, reliable)
    ↓
If WhatsApp fails → Try MSG91 SMS (paid, backup)
    ↓
Log everything to database
```

---

##  Backend Logs

When alert is sent, you'll see:

```
 Sending WhatsApp message
   From: whatsapp:+14155238886
   To: whatsapp:+919347688730
   Message:  *AegisAI Emergency Alert*...
 WhatsApp message sent successfully!
   Message SID: SMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   Status: queued
```

---

##  Important Notes

### Sandbox Requirement:
- Recipients must "join" sandbox first (one-time)
- Send join code to sandbox number via WhatsApp
- Perfect for testing and demo

### For Production:
- Apply for WhatsApp Business API
- Get your own WhatsApp number
- No "join" requirement
- Unlimited messages

---

##  Troubleshooting

### "Recipient not joined"
→ Send join code from +91 93476 88730 to sandbox number

### "Authentication failed"
→ Check Account SID and Auth Token in `.env`

### "Module not found: twilio"
→ Run: `pip install twilio`

### WhatsApp not received
→ Check backend logs for errors
→ Verify recipient joined sandbox
→ Check Twilio console: https://console.twilio.com/monitor/logs/messages

---

##  Full Documentation

Read `WHATSAPP_SETUP_GUIDE.md` for detailed step-by-step instructions.

---

##  Checklist

- [ ] Install twilio: `pip install twilio`
- [ ] Create Twilio account
- [ ] Setup WhatsApp sandbox
- [ ] Send join code from +91 93476 88730
- [ ] Get Account SID and Auth Token
- [ ] Update `.env` file
- [ ] Restart Django backend
- [ ] Test from Flutter app
- [ ] Verify WhatsApp delivery

---

##  You're Done!

Once you complete these steps, your AegisAI app will send automatic WhatsApp alerts for free!

**Total time: ~15 minutes**
**Cost: $0 (free trial)**

---

**Need help? Let me know which step you're stuck on!**
