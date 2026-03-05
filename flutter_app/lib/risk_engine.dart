import 'dart:math';

enum RiskStatus { safe, medium, high }

class RiskResult {
  final int score;
  final RiskStatus status;
  final List<String> reasons;
  final bool highRiskTriggered;

  RiskResult({
    required this.score,
    required this.status,
    required this.reasons,
    required this.highRiskTriggered,
  });
}

/// Rule-based risk engine with persistence, decay, and cooldown
class RiskEngine {
  // Thresholds
  static const int safeThreshold = 39;
  static const int mediumThreshold = 69;
  static const double abnormalMagnitudeThreshold = 20.0;
  
  // Persistence requirements
  static const int requiredSpikes = 2;
  static const Duration spikeWindow = Duration(seconds: 4);
  
  // Decay and cooldown
  static const Duration decayInterval = Duration(seconds: 2);
  static const int decayAmount = 10;
  static const Duration cooldownDuration = Duration(seconds: 60);
  
  // Night time (after 10 PM)
  static const int nightHourStart = 22;

  int _currentScore = 0;
  final List<DateTime> _recentSpikes = [];
  DateTime? _lastHighRiskTime;
  DateTime _lastDecayTime = DateTime.now();
  bool _highRiskTriggeredThisEvent = false;

  /// Process accelerometer data and return risk assessment
  RiskResult processAccelerometer(double x, double y, double z) {
    final now = DateTime.now();
    
    // Check if in cooldown period
    if (_lastHighRiskTime != null &&
        now.difference(_lastHighRiskTime!) < cooldownDuration) {
      return _buildResult(paused: true);
    }

    // Calculate magnitude
    final magnitude = sqrt(x * x + y * y + z * z);
    
    // Detect abnormal spike
    if (magnitude > abnormalMagnitudeThreshold) {
      _recentSpikes.add(now);
    }

    // Clean old spikes outside the window
    _recentSpikes.removeWhere((time) => now.difference(time) > spikeWindow);

    // Check for persistence (multiple spikes in window)
    if (_recentSpikes.length >= requiredSpikes) {
      _currentScore = min(100, _currentScore + 30);
      _recentSpikes.clear(); // Reset after scoring
    }

    // Apply time-based weight (night time)
    if (now.hour >= nightHourStart) {
      _currentScore = min(100, _currentScore + 5);
    }

    // Apply decay if no recent activity
    if (now.difference(_lastDecayTime) > decayInterval) {
      _currentScore = max(0, _currentScore - decayAmount);
      _lastDecayTime = now;
    }

    return _buildResult();
  }

  /// Simulate high risk for testing
  RiskResult simulateHighRisk() {
    _currentScore = 85;
    return _buildResult(forceHighRisk: true);
  }

  /// Reset after "I Am Safe" is clicked
  void resetAfterSafe() {
    _currentScore = 0;
    _recentSpikes.clear();
    _lastHighRiskTime = DateTime.now();
    _highRiskTriggeredThisEvent = false;
  }

  /// Mark high risk event as handled
  void markHighRiskHandled() {
    _lastHighRiskTime = DateTime.now();
    _highRiskTriggeredThisEvent = false;
  }

  RiskResult _buildResult({bool paused = false, bool forceHighRisk = false}) {
    if (paused) {
      return RiskResult(
        score: _currentScore,
        status: _getStatus(_currentScore),
        reasons: ['Cooldown active'],
        highRiskTriggered: false,
      );
    }

    final reasons = <String>[];
    final status = _getStatus(_currentScore);

    if (_recentSpikes.isNotEmpty) {
      reasons.add('Abnormal movement detected');
    }

    if (DateTime.now().hour >= nightHourStart) {
      reasons.add('Night-time context active');
    }

    // Trigger high risk only once per event
    bool shouldTrigger = false;
    if ((status == RiskStatus.high || forceHighRisk) && !_highRiskTriggeredThisEvent) {
      shouldTrigger = true;
      _highRiskTriggeredThisEvent = true;
    }

    return RiskResult(
      score: _currentScore,
      status: status,
      reasons: reasons,
      highRiskTriggered: shouldTrigger,
    );
  }

  RiskStatus _getStatus(int score) {
    if (score <= safeThreshold) return RiskStatus.safe;
    if (score <= mediumThreshold) return RiskStatus.medium;
    return RiskStatus.high;
  }

  int get currentScore => _currentScore;
}
