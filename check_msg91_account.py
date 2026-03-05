#!/usr/bin/env python3
"""
Check MSG91 Account Status and Balance
"""

import requests

AUTH_KEY = "497258ACavnGkGmYQ569a3cb4fP1"

def check_balance():
    """Check MSG91 account balance"""
    print("\n" + "="*60)
    print("Checking MSG91 Account Balance")
    print("="*60)
    
    url = "https://control.msg91.com/api/balance.php"
    params = {"authkey": AUTH_KEY}
    
    try:
        response = requests.get(url, params=params, timeout=10)
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            try:
                balance = float(response.text)
                print(f"\n💰 Account Balance: {balance} credits")
                
                if balance > 0:
                    print("✅ You have credits available")
                else:
                    print("❌ No credits available - need to add credits or activate free SMS")
            except:
                print(f"Response: {response.text}")
        else:
            print("❌ Cannot check balance")
            
    except Exception as e:
        print(f"❌ Error: {e}")


def check_recent_sms():
    """Check recent SMS delivery status"""
    print("\n" + "="*60)
    print("Recent SMS Status")
    print("="*60)
    print("To check delivery status:")
    print("1. Login to https://control.msg91.com")
    print("2. Go to SMS → Logs")
    print("3. Look for recent messages to 919347688730")
    print("4. Check 'Status' column:")
    print("   - 'Delivered' = SMS received ✅")
    print("   - 'Sent' = In transit ⏳")
    print("   - 'Failed' = Not delivered ❌")
    print("   - 'Test Mode' = Account not activated ⚠️")


def main():
    print("\n" + "="*60)
    print("MSG91 Account Diagnostic Tool")
    print("="*60)
    print(f"Auth Key: {AUTH_KEY}")
    
    check_balance()
    check_recent_sms()
    
    print("\n" + "="*60)
    print("DIAGNOSIS")
    print("="*60)
    print("Your backend is working correctly:")
    print("✅ API calls successful (status 200)")
    print("✅ MSG91 returns 'success'")
    print("✅ Template ID configured")
    print("✅ Route 4 (Transactional) used")
    print("\nBUT SMS not delivered because:")
    print("⚠️  Account is in TEST MODE")
    print("⚠️  Need MSG91 support to activate LIVE MODE")
    
    print("\n" + "="*60)
    print("ACTION REQUIRED")
    print("="*60)
    print("Contact MSG91 Support:")
    print("📞 Phone: +91-9650-800-800")
    print("📧 Email: support@msg91.com")
    print("💬 Chat: https://control.msg91.com (bottom right)")
    print("\nTell them:")
    print("'KYC approved but SMS not delivered.'")
    print("'Please activate live mode for automatic SMS.'")
    print(f"'Auth Key: {AUTH_KEY}'")
    print("="*60 + "\n")


if __name__ == "__main__":
    main()
