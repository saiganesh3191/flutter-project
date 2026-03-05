# Phone Number Auto-Fill from Backend

## Changes Made

### Backend Changes

1. **New Endpoint: Get Device Info**
   - URL: `/api/v1/device/info/`
   - Method: GET
   - Parameters: `device_token`
   - Returns: Device information including phone number
   
   ```json
   {
     "device_id": "uuid",
     "phone_number": "+916281190183",
     "platform": "android",
     "created_at": "2026-03-01T..."
   }
   ```

### Flutter Changes

1. **AlertManager - New Method**
   - `getDeviceInfoFromBackend()` - Fetches device info from backend
   - Returns phone number, device ID, platform, etc.

2. **Onboarding Screen**
   - Auto-fills phone number from backend (not local storage)
   - Loads phone number when screen opens
   - User doesn't need to re-enter their phone number

3. **Home Screen**
   - Displays phone number in a green card
   - Fetches phone number from backend
   - Shows "Your Phone Number" with the actual number

## How It Works

### When Admin Opens "Manage Contacts":
1. App calls `/api/v1/device/info/` with device token
2. Backend returns device info including phone number
3. Phone number field is auto-filled
4. Contacts are also loaded from backend
5. User can just click "Save & Continue" without re-entering anything

### Phone Number Display on Home Screen:
1. Home screen loads device info from backend
2. Displays phone number in a green card below stats
3. Shows checkmark to indicate it's verified

## Benefits

 Phone number comes from backend (single source of truth)
 No need to re-enter phone number every time
 Easy to see your registered phone number
 Consistent with backend data
 Works even if local storage is cleared

## Testing

1. **Admin Device:**
   - Login as admin
   - Go to Settings → Manage Contacts
   - Phone number should be auto-filled
   - Contacts should be auto-filled
   - Just click "Save & Continue"

2. **Home Screen:**
   - Should see green card with your phone number
   - Below the stats cards (Contacts and Alerts)

## API Endpoints Used

- `GET /api/v1/device/info/?device_token=<token>` - Get device info
- `GET /api/v1/contacts/?device_token=<token>` - Get contacts
- `POST /api/v1/device/update-phone/` - Update phone number
- `POST /api/v1/contacts/` - Save contact
