import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../local_database.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // User's own phone number
  final TextEditingController _userPhoneController = TextEditingController();
  
  // 5 contact slots with priority
  final List<TextEditingController> _nameControllers = List.generate(5, (_) => TextEditingController());
  final List<TextEditingController> _phoneControllers = List.generate(5, (_) => TextEditingController());
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    // Load user phone from local database
    final userPhone = LocalDatabase.getUserPhone();
    if (userPhone != null) {
      _userPhoneController.text = userPhone;
    }
    
    // Load contacts from local database
    final contacts = LocalDatabase.getContacts();
    for (var contact in contacts) {
      final priority = contact['priority'] as int;
      final index = priority - 1; // Convert priority 1-5 to index 0-4
      
      if (index >= 0 && index < 5) {
        _nameControllers[index].text = contact['name'] as String;
        _phoneControllers[index].text = contact['phone'] as String;
      }
    }
  }

  @override
  void dispose() {
    _userPhoneController.dispose();
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    // Validate user's phone number
    if (_userPhoneController.text.trim().isEmpty) {
      _showMessage('Please enter your phone number');
      return;
    }
    
    // Validate at least 1 contact
    int filledContacts = 0;
    for (int i = 0; i < 5; i++) {
      if (_nameControllers[i].text.trim().isNotEmpty && _phoneControllers[i].text.trim().isNotEmpty) {
        filledContacts++;
      }
    }

    if (filledContacts == 0) {
      _showMessage('Please add at least 1 trusted contact');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save user phone to local database
      await LocalDatabase.saveUserPhone(_userPhoneController.text.trim());

      // Generate device ID if not exists
      String? deviceId = LocalDatabase.getDeviceId();
      if (deviceId == null) {
        deviceId = const Uuid().v4();
        await LocalDatabase.saveDeviceId(deviceId);
      }

      // Save contacts to local database
      final contacts = <Map<String, dynamic>>[];
      for (int i = 0; i < 5; i++) {
        final name = _nameControllers[i].text.trim();
        final phone = _phoneControllers[i].text.trim();
        
        if (name.isNotEmpty && phone.isNotEmpty) {
          contacts.add({
            'name': name,
            'phone': phone,
            'priority': i + 1, // Priority 1-5
          });
        }
      }

      await LocalDatabase.saveContacts(contacts);

      print('✅ Saved ${contacts.length} contacts locally');

      _showMessage('Setup complete! All data saved locally.');

      // Navigate to home screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('Save error: $e');
      _showMessage('Error saving data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Emergency Contacts'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All data stored locally on your device. No backend server needed!',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // User's phone number
                  const Text(
                    'Your Phone Number',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _userPhoneController,
                    decoration: InputDecoration(
                      hintText: 'Enter your phone number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Emergency contacts
                  const Text(
                    'Emergency Contacts (Top 3 will receive alerts)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 5 contact slots
                  ...List.generate(5, (index) => _buildContactSlot(index)),
                  
                  const SizedBox(height: 32),
                  
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save & Continue',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildContactSlot(int index) {
    final priority = index + 1;
    final isTopPriority = priority <= 3;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTopPriority ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTopPriority ? Colors.red.shade200 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isTopPriority ? Colors.red : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$priority',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Contact $priority',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isTopPriority) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'ALERT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameControllers[index],
            decoration: InputDecoration(
              hintText: 'Name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneControllers[index],
            decoration: InputDecoration(
              hintText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}
