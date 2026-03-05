import 'package:flutter_test/flutter_test.dart';
import 'package:aegis_ai/risk_engine.dart';

void main() {
  group('RiskEngine Tests', () {
    late RiskEngine engine;

    setUp(() {
      engine = RiskEngine();
    });

    test('Initial score should be 0', () {
      expect(engine.currentScore, 0);
    });

    test('Single spike should NOT trigger high risk', () {
      // Single abnormal spike
      final result = engine.processAccelerometer(25.0, 0.0, 0.0);
      
      expect(result.status, isNot(RiskStatus.high));
    });

    test('Multiple spikes in window should increase score', () {
      // First spike
      engine.processAccelerometer(25.0, 0.0, 0.0);
      
      // Second spike within window
      final result = engine.processAccelerometer(25.0, 0.0, 0.0);
      
      expect(result.score, greaterThan(0));
    });

    test('Simulate high risk should trigger alert', () {
      final result = engine.simulateHighRisk();
      
      expect(result.status, RiskStatus.high);
      expect(result.highRiskTriggered, true);
    });

    test('High risk should only trigger once per event', () {
      final result1 = engine.simulateHighRisk();
      expect(result1.highRiskTriggered, true);
      
      // Second call should not trigger again
      final result2 = engine.processAccelerometer(0.0, 0.0, 0.0);
      expect(result2.highRiskTriggered, false);
    });

    test('Reset after safe should clear score', () {
      engine.simulateHighRisk();
      expect(engine.currentScore, greaterThan(0));
      
      engine.resetAfterSafe();
      expect(engine.currentScore, 0);
    });

    test('Score should decay over time', () async {
      // Trigger high score
      engine.simulateHighRisk();
      final initialScore = engine.currentScore;
      
      // Wait for decay interval
      await Future.delayed(const Duration(seconds: 3));
      
      // Process normal movement
      final result = engine.processAccelerometer(0.0, 0.0, 9.8);
      
      expect(result.score, lessThan(initialScore));
    });

    test('Cooldown should prevent immediate re-trigger', () {
      engine.simulateHighRisk();
      engine.markHighRiskHandled();
      
      // Try to trigger again immediately
      final result = engine.simulateHighRisk();
      
      // Should be in cooldown
      expect(result.reasons, contains('Cooldown active'));
    });

    test('Risk status thresholds', () {
      // Safe
      var result = engine.processAccelerometer(0.0, 0.0, 9.8);
      expect(result.status, RiskStatus.safe);
      
      // Simulate medium
      for (int i = 0; i < 3; i++) {
        engine.processAccelerometer(25.0, 0.0, 0.0);
      }
      result = engine.processAccelerometer(0.0, 0.0, 9.8);
      
      // Should be at least medium or high
      expect(result.status, isNot(RiskStatus.safe));
    });
  });
}
