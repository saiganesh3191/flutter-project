# Location Permission Fix

## Problem
The app shows: `Location error: User denied permissions to access the device's location.`

This means the location permission was denied, so the app can't get GPS coordinates for emergency alerts.

## Solution

### Option 1: Grant Permission When Starting Monitoring

1. On the home screen, click the **"Start"** button
2. A message will appear: "Location permission required. Please grant permission."
3. Click **"Grant"** button
4. Android will show permission dialog
5. Select **"Allow"** or **"Allow only while using the app"**
6. Now you can start monitoring

### Option 2: Grant Permission in Settings

1. Go to Settings → Manage Contacts
2. Click "Save & Continue"
3. Android will ask for permissions
4. Grant **Location** permission
5. Grant **Physical Activity** permission (optional)
6. Return to home screen

### Option 3: Manual Settings

If the app doesn't ask for permission:

1. Go to Android Settings
2. Apps → AegisAI
3. Permissions
4. Location → Allow
5. Physical Activity → Allow (optional)
6. Return to app

## Why Location Permission is Needed

The app needs location permission to:
- Get GPS coordinates when alert is triggered
- Send location to emergency contacts
- Enable contacts to find you quickly
- Provide location link in WhatsApp/SMS

## Permissions Required

### Location (Required)
- **Why**: Get GPS coordinates for emergency alerts
- **When**: Only when monitoring is active
- **Privacy**: Location is only sent when alert is triggered

### Physical Activity (Optional)
- **Why**: Detect movement patterns for risk detection
- **When**: Only when monitoring is active
- **Privacy**: Data stays on device, not sent to server

### SMS (Not Required)
- **Why**: Was used for old SMS feature
- **Status**: No longer needed (backend sends SMS)
- **Can be denied**: App will work fine without it

## Testing

After granting permissions:

1. Start monitoring (green "Start" button)
2. Click "Test Alert" button
3. Check backend logs - should show GPS coordinates
4. Check WhatsApp message - should include location link
5. No more "Location error" messages

## Troubleshooting

### Permission Dialog Doesn't Appear

If Android doesn't show the permission dialog:

1. Uninstall the app
2. Reinstall: `flutter run`
3. Login and setup contacts
4. Permission dialog should appear

### Permission Keeps Getting Denied

1. Go to Android Settings → Apps → AegisAI
2. Permissions → Location
3. Make sure it's set to "Allow" or "Allow only while using the app"
4. NOT "Deny" or "Ask every time"

### Location Still Not Working

1. Check if GPS is enabled on device
2. Go to Android Settings → Location
3. Make sure Location is ON
4. Try going outside (GPS works better outdoors)

## Changes Made

### Onboarding Screen
- Now always requests permissions (even for existing users)
- Shows helpful message if permissions denied
- Still allows navigation to home screen

### Home Screen
- Checks permissions before starting monitoring
- Shows snackbar with "Grant" button if denied
- Provides clear feedback when permissions granted/denied

### Permission Flow
```
User clicks "Start" 
  → Check if location permission granted
  → If NO: Show message with "Grant" button
  → If YES: Start monitoring
```

## Summary

Location permission is required for the app to work properly. The app now makes it easy to grant permissions with clear prompts and helpful messages. Just click "Grant" when asked, and you're good to go!
