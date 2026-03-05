#  Firebase Push Notifications Setup

##  What's Done

1.  Firebase project created: `aegisai-c1fd7`
2.  `google-services.json` added to Android app
3.  Android build files updated with Firebase plugin
4.  Flutter packages added: `firebase_core`, `firebase_messaging`
5.  Firebase service created in Flutter app
6.  Backend updated with FCM token storage
7.  Push notification sending function added
8.  API endpoint created: `/api/v1/device/update-fcm-token/`

##  Next Steps

### Step 1: Get Firebase Server Key

1. Go to Firebase Console: https://console.firebase.google.com/project/aegisai-c1fd7/settings/cloudmessaging
2. Scroll down to "Cloud Messaging API (Legacy)"
3. Copy the **Server key** (starts with `AAAA...`)

### Step 2: Update Backend .env File

Open `django_backend/.env` and replace:
```env
FIREBASE_SERVER_KEY=YOUR_SERVER_KEY_HERE
```

With your actual server key:
```env
FIREBASE_SERVER_KEY=AAAA...your-actual-key
```

### Step 3: Run Database Migration

```bash
cd django_backend
python manage.py makemigrations
python manage.py migrate
```

### Step 4: Install Flutter Packages

```bash
cd aegis_app
flutter pub get
```

### Step 5: Restart Backend

```bash
cd django_backend
python manage.py runserver 0.0.0.0:8000
```

### Step 6: Rebuild Flutter App

```bash
cd aegis_app
flutter run
```

##  How It Works

1. **App starts** → Firebase initializes → Gets FCM token
2. **FCM token** → Sent to backend → Stored in database
3. **Alert triggered** → Backend sends:
   -  Push notification to device owner
   -  WhatsApp to top 3 contacts
   -  SMS fallback if WhatsApp fails

##  Notification Flow

```
User triggers alert
    ↓
Backend receives alert
    ↓
1. Send push notification to device (instant alert on phone)
2. Send WhatsApp to contact 1 (Siri)
3. Send WhatsApp to contact 2 (Sukanya)
4. Send WhatsApp to contact 3 (Emergency)
    ↓
If WhatsApp fails → Send SMS via MSG91
```

##  Firebase Credentials

- **Project ID**: `aegisai-c1fd7`
- **Project Number**: `819754107565`
- **API Key**: `AIzaSyAfPgEjytoTZWH2DKIzJOzkXA-KxwuCPgk`
- **App ID**: `1:819754107565:android:4a2526ad0037bee8ab7c24`
- **Server Key**: (Get from Cloud Messaging tab)

##  Benefits

- **Instant alerts**: Push notifications arrive in <1 second
- **No SMS cost**: Push notifications are 100% free
- **Works offline**: Notifications queue and deliver when online
- **Rich content**: Can include images, actions, sounds
- **Battery efficient**: Uses Google's infrastructure

##  Troubleshooting

**No FCM token?**
- Check app permissions (Notifications allowed)
- Check Firebase initialization logs in Flutter console

**Push not received?**
- Verify Server Key is correct in `.env`
- Check backend logs for FCM response
- Ensure device has internet connection

**Build errors?**
- Run `flutter clean` then `flutter pub get`
- Sync Gradle files in Android Studio
