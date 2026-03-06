import 'package:flutter/material.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../sensor_service.dart';
import '../risk_engine.dart';
import '../alert_manager.dart';
import '../alert_orchestrator_night.dart';
import '../alert_sender_impl.dart';
import '../storage_service.dart';
import '../background_service.dart';
import '../widgets/risk_meter.dart';
import 'alert_countdown_dialog.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final SensorService _sensorService = SensorService();
  final AlertManager _alertManager = AlertManager();
  final StorageService _storage = StorageService();
  late final AlertOrchestratorNight _orchestrator;
  
  bool _isMonitoring = false;
  int _riskScore = 0;
  RiskStatus _riskStatus = RiskStatus.safe;
  List<String> _reasons = [];
  List<Map<String, dynamic>> _contacts = [];
  String _userPhone = '';
  AlertStage _alertStage = AlertStage.idle;
  bool _isDialogShowing = false;
  TimeMode _timeMode = TimeMode.day;
  
  StreamSubscription? _riskSubscription;
  StreamSubscription? _alertSubscription;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    
    // Initialize AlertOrchestratorNight with production night mode settings
    _orchestrator = AlertOrchestratorNight(
      sensorService: _sensorService,
      sender: AegisAlertSender(),
      config: const AlertPolicyConfig(
        // Day mode settings (6 AM - 9 PM)
        requiredHighSamplesDay: 10,        // ~1.5s
        minGyroForEvidenceDay: 1.5,        // rad/s
        minJerkForEvidenceDay: 12.0,       // m/s³
        cooldownDay: Duration(seconds: 30),
        
        // Night mode settings (10 PM - 5 AM) - MORE SENSITIVE
        requiredHighSamplesNight: 8,       // ~1.2s (20% faster)
        minGyroForEvidenceNight: 1.2,      // rad/s (20% lower)
        minJerkForEvidenceNight: 10.0,     // m/s³ (17% lower)
        cooldownNight: Duration(seconds: 60), // 2x longer (prevents spam)
        
        // Cancel window (same for all times)
        cancelWindow: Duration(seconds: 8),
        
        // Time ranges
        nightStartHour: 22,      // 10 PM
        nightEndHour: 5,         // 5 AM
        peakNightStartHour: 23,  // 11 PM (most dangerous)
        peakNightEndHour: 4,     // 4 AM
      ),
    );
    
    _setupRiskListener();
    _setupAlertListener();
    _loadContacts();
    _loadUserPhone();
    _initializeBackgroundService();
    
    // Pulse animation for monitoring indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Rotation animation for shield
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  Future<void> _initializeBackgroundService() async {
    await BackgroundMonitoringService.initialize();
    
    // Check if service is already running
    final isRunning = await BackgroundMonitoringService.isRunning();
    if (isRunning && mounted) {
      setState(() {
        _isMonitoring = true;
      });
    }
  }

  @override
  void dispose() {
    _riskSubscription?.cancel();
    _alertSubscription?.cancel();
    _orchestrator.dispose();
    _sensorService.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    final contacts = await _alertManager.getContactsFromBackend();
    if (contacts != null && mounted) {
      setState(() {
        _contacts = contacts;
      });
    }
  }

  Future<void> _loadUserPhone() async {
    try {
      final deviceInfo = await _alertManager.getDeviceInfoFromBackend();
      if (deviceInfo != null && deviceInfo['phone_number'] != null && mounted) {
        setState(() {
          _userPhone = deviceInfo['phone_number'];
        });
      }
    } catch (e) {
      print('Error loading phone: $e');
    }
  }

  void _setupRiskListener() {
    // Listen to sensor frames for UI updates
    _riskSubscription = _sensorService.riskStream.listen((frame) {
      if (!mounted) return;
      
      setState(() {
        _riskScore = frame.assessment.score;
        _riskStatus = _convertState(frame.assessment.state);
      });
    });
  }

  void _setupAlertListener() {
    // Listen to alert orchestrator for alert flow
    _alertSubscription = _orchestrator.statusStream.listen((status) {
      if (!mounted) return;
      
      setState(() {
        _alertStage = status.stage;
        _reasons = status.reasons;
        _timeMode = status.timeMode; // Update time mode
      });

      // Show countdown dialog when arming (only once)
      if (status.stage == AlertStage.arming && !_isDialogShowing) {
        _isDialogShowing = true;
        _showCountdownDialog(status);
      } 
      // Dismiss dialog and show confirmation when triggered
      else if (status.stage == AlertStage.triggered) {
        _isDialogShowing = false;
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
        _showAlertSentConfirmation();
      }
    });
  }

  void _showCountdownDialog(AlertStatus status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertCountdownDialog(
        initialSeconds: status.remainingCancelSeconds,
        score: status.score,
        reasons: status.reasons,
        onCancel: () {
          _isDialogShowing = false;
          _orchestrator.cancelArming();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Alert cancelled - You\'re safe'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showAlertSentConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Alert Sent'),
          ],
        ),
        content: const Text(
          'Emergency alert has been sent to your contacts via SMS and WhatsApp.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  RiskStatus _convertState(RiskState state) {
    switch (state) {
      case RiskState.safe:
        return RiskStatus.safe;
      case RiskState.medium:
        return RiskStatus.medium;
      case RiskState.high:
        return RiskStatus.high;
    }
  }

  Future<void> _toggleMonitoring() async {
    // Check permissions before starting monitoring
    if (!_isMonitoring) {
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Location permission required. Please grant permission.'),
              action: SnackBarAction(
                label: 'Grant',
                onPressed: _requestPermissions,
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    }
    
    setState(() => _isMonitoring = !_isMonitoring);

    if (_isMonitoring) {
      // Start foreground service for background monitoring
      final deviceToken = await _storage.getDeviceToken();
      if (deviceToken != null) {
        await BackgroundMonitoringService.startService(
          deviceToken: deviceToken,
          backendUrl: 'http://localhost:8000', // Not used anymore
        );
      }
      
      // Start sensor service and orchestrator
      await _sensorService.start();
      await _orchestrator.start();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Monitoring started - Alert system active'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      // Stop both services
      await BackgroundMonitoringService.stopService();
      _orchestrator.stop();
      _sensorService.stop();
      
      // Reset risk score when stopping
      setState(() {
        _riskScore = 0;
        _riskStatus = RiskStatus.safe;
        _reasons = [];
        _alertStage = AlertStage.idle;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monitoring stopped'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool> _checkPermissions() async {
    final locationStatus = await Permission.location.status;
    return locationStatus.isGranted;
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.activityRecognition,
    ].request();

    final allGranted = statuses.values.every((status) => status.isGranted);
    
    if (allGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissions granted! You can now start monitoring.'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Some permissions were denied. App may not work properly.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _testHighRisk() {
    if (!_isMonitoring) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable monitoring first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    _sensorService.simulateHighRisk();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧪 Test alert triggered - Watch for countdown'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout() async {
    // Stop monitoring first
    if (_isMonitoring) {
      await BackgroundMonitoringService.stopService();
      _orchestrator.stop();
      _sensorService.stop();
    }
    
    // Clear all stored data
    await _storage.clearAll();
    
    // Navigate to login screen
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Color _getRiskColor() {
    if (_alertStage == AlertStage.arming) return Colors.orange;
    if (_alertStage == AlertStage.cooldown) return Colors.purple;
    
    switch (_riskStatus) {
      case RiskStatus.safe:
        return Colors.green;
      case RiskStatus.medium:
        return Colors.orange;
      case RiskStatus.high:
        return Colors.red;
    }
  }

  IconData _getRiskIcon() {
    if (_alertStage == AlertStage.arming) return Icons.warning_amber;
    if (_alertStage == AlertStage.cooldown) return Icons.timer;
    
    switch (_riskStatus) {
      case RiskStatus.safe:
        return Icons.check_circle;
      case RiskStatus.medium:
        return Icons.warning;
      case RiskStatus.high:
        return Icons.error;
    }
  }

  String _getRiskText() {
    if (_alertStage == AlertStage.arming) return 'Alert Arming!';
    if (_alertStage == AlertStage.cooldown) return 'Cooldown';
    
    switch (_riskStatus) {
      case RiskStatus.safe:
        return 'You\'re Safe';
      case RiskStatus.medium:
        return 'Stay Alert';
      case RiskStatus.high:
        return 'High Risk!';
    }
  }

  String _getTimeModeText() {
    switch (_timeMode) {
      case TimeMode.day:
        return '☀️ Day Mode';
      case TimeMode.transition:
        return '🌅 Transition';
      case TimeMode.night:
        return '🌙 Night Mode';
      case TimeMode.peakNight:
        return '🌑 Peak Night';
    }
  }

  Color _getTimeModeColor() {
    switch (_timeMode) {
      case TimeMode.day:
        return Colors.orange;
      case TimeMode.transition:
        return Colors.purple;
      case TimeMode.night:
        return Colors.indigo;
      case TimeMode.peakNight:
        return Colors.black87;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getRiskColor().withOpacity(0.1),
              Colors.white,
              _getRiskColor().withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 80,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield, color: _getRiskColor(), size: 24),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AegisAI',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 18,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  centerTitle: true,
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.settings, color: Colors.black54),
                    onSelected: (value) {
                      if (value == 'manage') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                        ).then((_) {
                          _loadContacts();
                          _loadUserPhone();
                          setState(() {});
                        });
                      } else if (value == 'logout') {
                        _logout();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'manage',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Manage Contacts'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Logout', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Time Mode Indicator
                      _buildTimeModeIndicator(),
                      
                      const SizedBox(height: 16),
                      
                      // Main Status Card with Animated Shield
                      _buildStatusCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Control Buttons
                      _buildControlButtons(),
                      
                      const SizedBox(height: 24),
                      
                      // Stats Cards
                      _buildStatsCards(),
                      
                      const SizedBox(height: 16),
                      
                      // Phone Number Card
                      if (_userPhone.isNotEmpty) _buildPhoneCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Contacts Section
                      _buildContactsSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Recent Activity
                      if (_reasons.isNotEmpty) _buildActivitySection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeModeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getTimeModeColor().withOpacity(0.2),
            _getTimeModeColor().withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTimeModeColor().withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _timeMode == TimeMode.day ? Icons.wb_sunny :
            _timeMode == TimeMode.transition ? Icons.wb_twilight :
            _timeMode == TimeMode.night ? Icons.nightlight_round :
            Icons.dark_mode,
            color: _getTimeModeColor(),
            size: 24,
          ),
          const SizedBox(width: 12),
          Text(
            _getTimeModeText(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getTimeModeColor(),
            ),
          ),
          const SizedBox(width: 8),
          if (_timeMode == TimeMode.night || _timeMode == TimeMode.peakNight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTimeModeColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'ENHANCED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return RiskMeter(
      riskScore: _riskScore,
      status: _getRiskText(),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: _isMonitoring ? Icons.pause_circle : Icons.play_circle,
            label: _isMonitoring ? 'Stop' : 'Start',
            color: _isMonitoring ? Colors.orange : Colors.green,
            onTap: _toggleMonitoring,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            icon: Icons.warning_amber,
            label: 'Test Alert',
            color: Colors.red,
            onTap: _testHighRisk,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            value: '${_contacts.length}',
            label: 'Contacts',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            icon: Icons.notifications_active,
            value: _isMonitoring ? 'ON' : 'OFF',
            label: 'Alerts',
            color: _isMonitoring ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.phone_android, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Phone Number',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userPhone,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.white, size: 24),
        ],
      ),
    );
  }

  Widget _buildContactsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                  ).then((_) => _loadContacts());
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_contacts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No contacts added yet',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ..._contacts.take(3).map((contact) => _buildContactTile(contact)),
        ],
      ),
    );
  }

  Widget _buildContactTile(Map<String, dynamic> contact) {
    final priority = contact['priority'] as int;
    final isTopPriority = priority <= 3;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTopPriority ? Colors.red.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isTopPriority ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact['phone'] as String,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (isTopPriority)
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
      ),
    );
  }

  Widget _buildActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._reasons.map((reason) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: _getRiskColor()),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
