# AegisAI Architecture

## System Overview

```

                     Flutter Android App                      

  UI Layer (3 screens + 1 popup)                             
   Onboarding Screen                                       
   Home Screen (Dashboard)                                
   Alert Popup (Confirmation)                             
   Alert Sent Screen                                       

  Service Layer                                               
   SensorService: Accelerometer + Location                
   RiskEngine: Rule-based scoring                         
   AlertManager: SMS + Backend sync                       
   StorageService: Local persistence                      

                            
                             HTTP REST API
                            

                    Django REST Backend                       

  API Endpoints                                               
   /api/v1/device/register/                              
   /api/v1/contacts/                                      
   /api/v1/risk-events/                                   
   /api/v1/alerts/                                        

  Database (PostgreSQL/SQLite)                               
   Device                                                  
   TrustedContact                                         
   RiskEvent                                              
   Alert                                                   

```

## Data Flow

### 1. Onboarding Flow
```
User Input → StorageService (local) → AlertManager → Backend API
                                                    → Device Token
```

### 2. Monitoring Flow
```
Accelerometer → SensorService → RiskEngine → Risk Score
                                           → Reasons
                                           → High Risk Trigger?
```

### 3. Alert Flow
```
High Risk → Alert Popup (5s countdown)
         → "I Am Safe" → Reset + Cooldown
         → Timer/Manual → AlertManager → SMS (device)
                                        → Backend Log
```

## Risk Engine Logic

### Inputs
- Accelerometer (x, y, z)
- Current time (night detection)
- Optional: Location context

### Processing
1. Calculate magnitude: `sqrt(x² + y² + z²)`
2. Detect spikes: magnitude > threshold
3. Check persistence: 2-3 spikes within 3-5 seconds
4. Apply time weight: +5 after 10 PM
5. Apply decay: -10 every 2 seconds if normal
6. Check cooldown: 60 seconds after high-risk event

### Outputs
- Score (0-100)
- Status (Safe/Medium/High)
- Reasons (list of strings)
- High Risk Triggered (boolean, once per event)

## Security Considerations

### Privacy
- No raw sensor data stored (only summaries)
- Location shared only in alerts
- Minimal data collection

### Authentication
- Device token-based auth
- Contact validation (must be registered)
- Rate limiting on alerts

### Permissions
- Runtime permission requests
- Graceful degradation if denied
- Clear user messaging

## Performance

### Battery Optimization
- Throttled sensor sampling (500ms)
- Periodic location updates (20s)
- Efficient risk calculation

### Background Stability
- Foreground service for monitoring
- Clean start/stop lifecycle
- Proper stream cancellation

## Testing Strategy

### Unit Tests
- Risk engine scoring rules
- Persistence logic
- Decay and cooldown

### Integration Tests
- "Test High Risk" flow
- Alert sending
- Backend API calls

### Manual Testing
- Real device with SIM
- Background monitoring
- Permission handling

## Deployment

### Flutter App
- Android APK/AAB
- Minimum SDK: 23 (Android 6.0)
- Target SDK: 34 (Android 14)

### Django Backend
- Gunicorn + Nginx
- PostgreSQL database
- Environment-based config
- CORS for mobile clients

## Future Enhancements (Not in MVP)

- Multiple trusted contacts
- Location-based risk zones
- ML-based risk prediction
- iOS support
- Push notifications
- Alert history in app
