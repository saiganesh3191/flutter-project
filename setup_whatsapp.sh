#!/bin/bash

echo "=========================================="
echo "AegisAI WhatsApp Integration Setup"
echo "=========================================="
echo ""

# Install Twilio
echo "📦 Installing Twilio library..."
cd django_backend
pip install twilio

echo ""
echo "✅ Twilio library installed!"
echo ""

# Update requirements
echo "📝 Updating requirements.txt..."
pip freeze > requirements.txt

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Create Twilio account: https://www.twilio.com/try-twilio"
echo "2. Setup WhatsApp sandbox"
echo "3. Update .env file with credentials"
echo "4. Restart Django backend"
echo "5. Test from Flutter app!"
echo ""
echo "Read WHATSAPP_SETUP_GUIDE.md for detailed instructions."
echo ""
