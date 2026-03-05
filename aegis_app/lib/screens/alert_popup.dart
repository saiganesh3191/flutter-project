import 'package:flutter/material.dart';
import 'dart:async';
import '../sensor_service.dart';
import '../alert_manager.dart';
import 'alert_sent_screen.dart';

class AlertPopup extends StatefulWidget {
  final SensorService sensorService;

  const AlertPopup({
    super.key,
    required this.sensorService,
  });

  @override
  State<AlertPopup> createState() => _AlertPopupState();
}

class _AlertPopupState extends State<AlertPopup> {
  static const int countdownSeconds = 5;
  int _remainingSeconds = countdownSeconds;
  Timer? _countdownTimer;
  final AlertManager _alertManager = AlertManager();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _sendAlert('timer');
      }
    });
  }

  void _onIAmSafe() {
    _countdownTimer?.cancel();
    // User confirmed they're safe - just close the popup
    Navigator.of(context).pop();
  }

  void _onSendAlertNow() {
    _countdownTimer?.cancel();
    _sendAlert('manual');
  }

  Future<void> _sendAlert(String triggeredBy) async {
    final position = widget.sensorService.lastPosition;
    
    final success = await _alertManager.sendAlert(
      position: position,
      reason: 'High risk detected',
      triggeredBy: triggeredBy,
    );

    // Alert has been handled
    if (mounted) {
      Navigator.of(context).pop(); // Close popup
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AlertSentScreen(success: success),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠ High Risk Detected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              '$_remainingSeconds',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onIAmSafe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'I Am Safe',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSendAlertNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Send Alert Now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
