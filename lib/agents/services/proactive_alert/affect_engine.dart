import 'dart:math';
import 'affective_state.dart';
import 'alert_intent.dart';

/// Affect AI: Converts Risk/Context -> Affective State 🧠🤖
///
/// Emergent emotion system that influences behavioral style.
class AffectEngine {
  static final AffectEngine _instance = AffectEngine._internal();
  factory AffectEngine() => _instance;
  AffectEngine._internal();

  /// Map of machine ID to its current Affective State
  final Map<String, AffectiveState> _states = {};

  AffectiveState getState(String machineId) =>
      _states[machineId] ?? const AffectiveState();

  /// Manually update state (used for swarm propagation)
  void forceUpdateState(String machineId, AffectiveState state) {
    _states[machineId] = _regulate(state);
  }

  /// Updates affect based on a new alert/risk assessment
  void processAlertImpact(String machineId, AlertIntent alert) {
    final currentState = getState(machineId);

    // 1. Prediction AI -> Affect Mapping
    double confidenceDelta = 0.0;
    double stressDelta = 0.0;
    double urgencyDelta = 0.0;

    if (alert.severity == AlertSeverity.critical ||
        alert.severity == AlertSeverity.high) {
      stressDelta = 0.3;
      confidenceDelta = -0.2;
    }

    if (alert.horizon == AlertTimeHorizon.immediate) {
      urgencyDelta = 0.4;
    }

    // 2. State Integration (Math, not feelings)
    final newState = currentState.copyWith(
      confidence: (currentState.confidence + confidenceDelta).clamp(0.0, 1.0),
      stress: (currentState.stress + stressDelta).clamp(0.0, 1.0),
      urgency: (currentState.urgency + urgencyDelta).clamp(0.0, 1.0),
      curiosity: alert.domain == AlertDomain.hardware ? 0.3 : 0.1,
    );

    // 3. Regulation AI: Dampen oscillation and enforce safe caps
    _states[machineId] = _regulate(newState);
  }

  /// Regulation AI: Prevents instability/overreaction
  AffectiveState _regulate(AffectiveState state) {
    // Cap stress to prevent "unstable" behavior
    double stress = state.stress;
    if (stress > 0.8) {
      stress = 0.8; // Safe ceiling
    }

    // If stress is extremely high, enforce high caution (lower confidence)
    double confidence = state.confidence;
    if (stress > 0.7) {
      confidence = min(confidence, 0.4);
    }

    return state.copyWith(
      stress: stress,
      confidence: confidence,
    );
  }

  /// Motor AI: Translates AffectiveState -> Motor Bias
  EmotionBias calculateBias(String machineId) {
    final s = getState(machineId);

    // Logic: Confident -> Fast/DECISIVE. Stressed -> Slow/PRECISE.
    double speedMult = 1.0;
    double smooth = 1.0;
    double pauseFreq = 0.0;
    String posture = 'Stable';
    String color = 'Blue';

    // Confidence scaling
    speedMult *= (0.5 + s.confidence * 0.5); // 0.5 to 1.0

    // Urgency scaling
    if (s.urgency > 0.5) {
      speedMult *= 1.5;
      pauseFreq = 0.0; // Reduced hesitation
    }

    // Stress scaling
    if (s.stress > 0.4) {
      speedMult *= 0.7; // Slower
      smooth = 0.5; // More "jittery"/careful micro-adjustments
      pauseFreq = 0.2; // Delighted/Micro-pauses
      posture = 'Retraction';
      color = s.stress > 0.7 ? 'Red' : 'Yellow';
    }

    // Curiosity scaling
    if (s.curiosity > 0.6) {
      posture = 'Lean-In';
      color = 'Purple'; // Planning/Deep focus
    }

    return EmotionBias(
      speedMultiplier: speedMult,
      motionSmoothness: smooth,
      pauseFrequency: pauseFreq,
      microAdjustmentGain: 1.0 + (s.stress * 0.5),
      posture: posture,
      lightColor: color,
    );
  }

  /// Dream Mode Emotional Consolidation
  /// Replays states and smooths them out over time.
  void consolidateDreams() {
    for (final entry in _states.entries) {
      final s = entry.value;
      // Decay "temporary" states like stress and urgency
      _states[entry.key] = s.copyWith(
        stress: (s.stress * 0.8), // 20% decay toward calm
        urgency: (s.urgency * 0.5), // Fast decay
        trust: (s.trust * 1.05).clamp(0.0, 0.95), // Trust builds slowly in idle
      );
    }
  }
}
