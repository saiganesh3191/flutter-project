import 'package:flutter/material.dart';
import '../local_database.dart';

class AlertSentScreen extends StatefulWidget {
  final bool success;

  const AlertSentScreen({
    super.key,
    required this.success,
  });

  @override
  State<AlertSentScreen> createState() => _AlertSentScreenState();
}

class _AlertSentScreenState extends State<AlertSentScreen> {
  int _contactCount = 0;

  @override
  void initState() {
    super.initState();
    _loadContactCount();
  }

  Future<void> _loadContactCount() async {
    final contacts = LocalDatabase.getTopContacts();
    setState(() => _contactCount = contacts.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Status'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: widget.success ? Colors.green : Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.success
                ? [Colors.green.shade50, Colors.white]
                : [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success/Error Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: widget.success ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.success ? Colors.green : Colors.orange).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  widget.success ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Status Text
              Text(
                widget.success ? '✅ Alert Sent!' : '⚠️ Alert Attempted',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: widget.success ? Colors.green.shade700 : Colors.orange.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: widget.success ? Colors.green : Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Notified $_contactCount emergency contact${_contactCount != 1 ? 's' : ''}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Divider(),
                    
                    const SizedBox(height: 16),
                    
                    // SMS Status
                    Row(
                      children: [
                        Icon(
                          Icons.sms,
                          color: widget.success ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'SMS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.success ? Colors.green.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.success ? 'Sent' : 'Attempted',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.success ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // WhatsApp Status
                    Row(
                      children: [
                        Icon(
                          Icons.chat,
                          color: widget.success ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.success ? Colors.green.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.success ? 'Sent' : 'Attempted',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.success ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Divider(),
                    
                    const SizedBox(height: 16),
                    
                    // Location Status
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: widget.success ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Location shared with Google Maps link',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Return Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.success ? Colors.green : Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Return to Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              if (!widget.success) ...[
                const SizedBox(height: 16),
                Text(
                  'Check SMS permissions and internet connection',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
