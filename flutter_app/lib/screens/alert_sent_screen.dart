import 'package:flutter/material.dart';
import '../storage_service.dart';

class AlertSentScreen extends StatefulWidget {
  final bool success;

  const AlertSentScreen({
    Key? key,
    required this.success,
  }) : super(key: key);

  @override
  State<AlertSentScreen> createState() => _AlertSentScreenState();
}

class _AlertSentScreenState extends State<AlertSentScreen> {
  final StorageService _storage = StorageService();
  String _contactName = '';

  @override
  void initState() {
    super.initState();
    _loadContactName();
  }

  Future<void> _loadContactName() async {
    final name = await _storage.getContactName();
    setState(() => _contactName = name ?? 'Unknown');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Status'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              widget.success ? Icons.check_circle : Icons.error,
              color: widget.success ? Colors.green : Colors.orange,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              widget.success ? 'Alert Sent to:' : 'Alert Attempted',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _contactName,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              widget.success
                  ? 'Location Shared Successfully.'
                  : 'SMS may have failed. Check permissions.',
              style: TextStyle(
                fontSize: 16,
                color: widget.success ? Colors.green : Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Return to Dashboard',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
