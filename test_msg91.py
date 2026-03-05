#!/usr/bin/env python3
"""
Quick MSG91 Account Test Script
Tests if MSG91 account is working and shows detailed response
"""

import requests
import json

# Your MSG91 credentials
AUTH_KEY = "497258ACavnGkGmYQ569a3cb4fP1"
SENDER_ID = "AEGSAI"
TEST_PHONE = "919347688730"  # Your test number

def test_promotional_route():
    """Test Route 1 (Promotional) - 9 AM to 9 PM IST"""
    print("\n" + "="*60)
    print("Testing Route 1 (Promotional)")
    print("="*60)
    
    url = "https://control.msg91.com/api/sendhttp.php"
    
    params = {
        "authkey": AUTH_KEY,
        "mobiles": TEST_PHONE,
        "message": "Test SMS from AegisAI - Route 1 Promotional",
        "sender": SENDER_ID,
        "route": "1",
        "country": "91",
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        # Analyze response
        if response.status_code == 200:
            if len(response.text) == 32 and response.text.isalnum():
                print("✅ SUCCESS! Message ID:", response.text)
                print("   SMS should be delivered shortly")
            elif "error" in response.text.lower():
                print("❌ ERROR:", response.text)
            else:
                print("⚠️  Unknown response:", response.text)
        else:
            print("❌ HTTP Error:", response.status_code)
            
    except Exception as e:
        print(f"❌ Exception: {e}")


def test_account_balance():
    """Check MSG91 account balance"""
    print("\n" + "="*60)
    print("Checking Account Balance")
    print("="*60)
    
    url = "https://control.msg91.com/api/balance.php"
    
    params = {
        "authkey": AUTH_KEY,
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        print(f"Status Code: {response.status_code}")
        print(f"Balance Response: {response.text}")
        
        if response.status_code == 200:
            print("✅ Account is accessible")
        else:
            print("❌ Cannot access account")
            
    except Exception as e:
        print(f"❌ Exception: {e}")


def main():
    print("\n" + "="*60)
    print("MSG91 Account Test - AegisAI")
    print("="*60)
    print(f"Auth Key: {AUTH_KEY}")
    print(f"Sender ID: {SENDER_ID}")
    print(f"Test Phone: {TEST_PHONE}")
    
    # Test balance first
    test_account_balance()
    
    # Test promotional route
    test_promotional_route()
    
    print("\n" + "="*60)
    print("Test Complete!")
    print("="*60)
    print("\nNext Steps:")
    print("1. Check phone", TEST_PHONE, "for SMS")
    print("2. If no SMS received, account might be in test mode")
    print("3. Contact MSG91 support: support@msg91.com")
    print("4. Or call: +91-9650-800-800")
    print("="*60 + "\n")


if __name__ == "__main__":
    main()
