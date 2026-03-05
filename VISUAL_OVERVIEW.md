# AegisAI Visual Overview

## System Architecture

```

                        USER'S ANDROID DEVICE                     
                                                                  
   
                      FLUTTER APP (UI)                         
                                                               
            
      Onboarding         Home         Alert Sent      
        Screen    →    Dashboard  →     Screen        
            
                             ↓                                
                                              
                       Alert Popup                          
                       (5s timer)                           
                                              
   
                              ↕                                   
   
                     SERVICE LAYER                             
                                                               
            
     Sensor   →    Risk   →   Alert   →  Storage    
     Service      Engine     Manager     Service    
            
         ↓              ↓              ↓            ↓         
   
                                                              

                                                  
    Accelerometer   Risk Score      SMS Send    Local Data
    + Location      Calculation                              
                                                  
          
                              ↓
                    
                       HTTP REST     
                       API Calls     
                    
                              ↓

                      DJANGO BACKEND SERVER                       
                                                                  
   
                      REST API ENDPOINTS                        
                                                               
    POST /api/v1/device/register/    → Device Token          
    POST /api/v1/contacts/           → Save Contact          
    POST /api/v1/risk-events/        → Log Risk Score        
    POST /api/v1/alerts/             → Log Alert + SMS       
   
                              ↓                                   
   
                      DATABASE (PostgreSQL)                    
                                                               
            
      Device     Trusted       Risk       Alert     
                 Contact      Event                 
            
   
                              ↓                                   
   
                OPTIONAL: TWILIO SMS GATEWAY                   
   

```

## Data Flow Diagram

```

   USER      
  Actions    

       
       → Toggle Monitoring ON
          → Start Sensors
              → Accelerometer Stream
                  → Risk Engine
                      → Calculate Score
                      → Check Persistence
                      → Apply Decay
                      → Output: Score + Reasons
       
       → Test High Risk
          → Simulate High Score
              → Trigger Popup
       
       → High Risk Detected
           → Show Confirmation Popup
               → "I Am Safe" → Reset + Cooldown
               
               → Timer Expires / "Send Alert Now"
                   → Get Location
                   → Build SMS Message
                   → Send SMS (Device)
                   → Log to Backend
                   → Show Success Screen
```

## UI Flow Diagram

```

  App Launch     

         
         → First Time?
            YES ↓
            
              Onboarding     
              - Name field   
              - Phone field  
              - Save button  
            
                     
                     → Request Permissions
                        → Location
                        → SMS
                        → Activity
                     
            NO ↓     ↓
            
         →    Home Screen    ←
               - Toggle                       
               - Risk Meter                   
               - Test Button                  
                             
                                               
                      → Test High Risk        
                         ↓                     
                           
                           Alert Popup      
                           - Countdown      
                           - I Am Safe    
                           - Send Now     
                         
                                  
                                  → I Am Safe
                                     → Reset & Return
                                  
                                  → Send Alert
                                      ↓
                         
                      →   Alert Sent     
                            - Contact Name 
                            - Success Msg  
                            - Return Btn   
                          
```

## Risk Engine Logic Flow

```

 Accelerometer   
   x, y, z       

         
         → Calculate Magnitude
            magnitude = sqrt(x² + y² + z²)
         
         → Check Spike
            IF magnitude > 20.0
            THEN record spike timestamp
         
         → Check Persistence
            IF 2+ spikes in last 4 seconds
            THEN score += 30
         
         → Apply Time Weight
            IF hour >= 22 (10 PM)
            THEN score += 5
         
         → Apply Decay
            IF no activity for 2 seconds
            THEN score -= 10
         
         → Check Cooldown
            IF in cooldown (60s after event)
            THEN pause detection
         
         → Output
             → Score (0-100)
             → Status (Safe/Medium/High)
             → Reasons (list)
             → High Risk Triggered (bool)
```

## Alert Flow Diagram

```

  High Risk      
  Detected       

         
         → Show Popup
            → Start 5s Timer
            → Display Buttons
         
         → User Action?
            
            → "I Am Safe" Clicked
               → Cancel Timer
               → Reset Score to 0
               → Start Cooldown (60s)
               → Close Popup
            
            → "Send Alert Now" Clicked
               → Cancel Timer
               → Send Alert
            
            → Timer Reaches 0
                → Send Alert
         
         → Send Alert Process
             → Get Current Location
             → Build SMS Message
                → Alert text
                → Google Maps link
             → Send SMS via Device
             → Log to Backend
                → POST /api/v1/alerts/
                → Store: location, reason, time
             → Show Success Screen
```

## Backend API Flow

```

  Flutter App    

         
         → First Launch
            → POST /api/v1/device/register/
                → Generate device_token
                → Return token to app
         
         → After Onboarding
            → POST /api/v1/contacts/
                → Validate device_token
                → Save contact
                → Link to device
         
         → During Monitoring (optional)
            → POST /api/v1/risk-events/
                → Validate device_token
                → Log score summary
                → Store reasons (no raw data)
         
         → Alert Sent
             → POST /api/v1/alerts/
                 → Validate device_token
                 → Verify contact registered
                 → Log alert with location
                 → Optional: Send SMS via Twilio
                 → Return success
```

## File Organization Visual

```
aegis-ai/

  Documentation (11 files)
    README.md
    QUICKSTART.md
    SETUP.md
    DEMO_GUIDE.md
    ARCHITECTURE.md
    DIRECTORY_STRUCTURE.md
    QUICK_REFERENCE.md
    PROJECT_SUMMARY.md
    VERIFICATION_CHECKLIST.md
    INDEX.md
    IMPLEMENTATION_COMPLETE.md

  Flutter App
    lib/
        main.dart (Entry)
        storage_service.dart
        risk_engine.dart
        sensor_service.dart
        alert_manager.dart
       screens/
            onboarding_screen.dart
            home_screen.dart
             alert_popup.dart
            alert_sent_screen.dart
    test/
        risk_engine_test.dart
    android/
         AndroidManifest.xml

   Django Backend
     aegisai/
          settings.py
         urls.py
         wsgi.py
     api/
          models.py (4 models)
          serializers.py
          views.py (4 endpoints)
          urls.py
         ‍ admin.py
          tests.py
```

## Component Interaction

```
          
   Sensors    → Risk Engine  →  UI Update   
 (Hardware)          (Logic)            (Display)   
          
                            
                            ↓
                     
                      High Risk?   
                     
                             YES
                            ↓
                     
                      Show Popup   
                     
                            
                     
                                   
               
               I Am Safe    Send Alert 
               
                                   
               
                 Reset         SMS     
               
                                   
                            
                               Backend    
                               Logging    
                            
```

## Technology Stack Visual

```

                    PRESENTATION LAYER                    
     
                Flutter Material UI                    
    (Screens, Widgets, Dialogs, Animations)           
     

                          ↕

                    BUSINESS LOGIC LAYER                  
         
    Risk        Sensor      Alert     Storage  
    Engine      Service     Manager   Service  
         

                          ↕

                    DATA/DEVICE LAYER                     
         
  Accelero-    Location      SMS       Local   
    meter        GPS       Telephony  Storage  
         

                          ↕

                    BACKEND API LAYER                     
     
           Django REST Framework                       
    (Endpoints, Serializers, Authentication)          
     

                          ↕

                    DATABASE LAYER                        
     
                PostgreSQL / SQLite                    
    (Device, Contact, RiskEvent, Alert tables)        
     

```

---

**Visual Guide Version:** 1.0.0

**Last Updated:** 2026-03-01

For detailed documentation, see [INDEX.md](INDEX.md)
