import 'package:flutter/material.dart';
import 'dart:async';
import '../sensor_service.dart';
import '../risk_engine.dart';
import 'alert_popup.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SensorService _sensorService = SensorService();
  
  bool _isMonitoring = false;
  int _riskScore = 0;
  RiskStatus _riskStatus = RiskStatus.safe;
  List<String> _reasons = [];
  
  StreamSubscription? _riskSubscription;

  @override
  void initState() {
    super.initState();
    _setupRiskListener();
  }

  @override
  void dispose() {
    _riskSubscription?.cancel();
    _sensorService.dispose();
    super.dispose();
  }

  void _setupRiskListener() {
    _riskSubscription = _sensorService.riskStream.listen((result) {
      if (!mounted) return;
      
      setState(() {
        _riskScore = result.score;
        _riskStatus = result.status;
        _reasons = result.reasons;
      });

      // Show confirmation popup on high risk
      if (result.highRiskTriggered) {
        _showAlertPopup();
      }
    });
  }

  void _toggleMonitoring() async {
    setState(() => _isMonitoring = !_isMonitoring);

    if (_isMonitoring) {
      await _sensorService.start();
    } else {
      _sensorService.stop();
    }
  }

  void _testHighRisk() {
    if (!_isMonitoring) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable monitoring first')),
      );
      return;
    }
    
    _sensorService.simulateHighRisk();
  }

  void _showAlertPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertPopup(
        sensorService: _sensorService,
      ),
    );
  }

  Color _getRiskColor() {
    switch (_riskStatus) {
      case RiskStatus.safe:
        return Colors.green;
      case RiskStatus.medium:
        return Colors.orange;
      case RiskStatus.high:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (_riskStatus) {
      case RiskStatus.safe:
        return 'Safe';
      case RiskStatus.medium:
        return 'Medium Risk';
      case RiskStatus.high:
        return 'High Risk';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AegisAI – Monitoring Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Monitoring toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monitoring: ${_isMonitoring ? "ON" : "OFF"}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: _isMonitoring,
                      onChanged: (_) => _toggleMonitoring(),
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Risk meter
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'LIVE RISK METER',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _riskScore / 100,
                      minHeight: 20,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(_getRiskColor()),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Risk Score: $_riskScore',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Status: ${_getStatusText()}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _getRiskColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Explainability section
            if (_reasons.isNotEmpty && _riskScore > 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reason:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._reasons.map((reason) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Text('• $reason'),
                          )),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Test button
            OutlinedButton(
              onPressed: _testHighRisk,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Test High Risk'),
            ),
          ],
        ),
      ),
    );
  }
}
