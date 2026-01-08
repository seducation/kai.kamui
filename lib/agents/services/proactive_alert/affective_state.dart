/// Affective State Vector (ASV) 🤖
///
/// Represents the 'emotional' state of a device organ as a mathematical vector.
/// This is NOT consciousness, but a state-driven affect that influences behavior.
class AffectiveState {
  final double confidence; // 0.0 -> 1.0 (Certainty of success)
  final double urgency; // 0.0 -> 1.0 (Time pressure)
  final double stress; // 0.0 -> 1.0 (System load/Risk)
  final double trust; // 0.0 -> 1.0 (Environmental predictability)
  final double curiosity; // 0.0 -> 1.0 (Novelty detection)

  const AffectiveState({
    this.confidence = 0.8,
    this.urgency = 0.0,
    this.stress = 0.0,
    this.trust = 0.9,
    this.curiosity = 0.1,
  });

  AffectiveState copyWith({
    double? confidence,
    double? urgency,
    double? stress,
    double? trust,
    double? curiosity,
  }) {
    return AffectiveState(
      confidence: confidence ?? this.confidence,
      urgency: urgency ?? this.urgency,
      stress: stress ?? this.stress,
      trust: trust ?? this.trust,
      curiosity: curiosity ?? this.curiosity,
    );
  }

  @override
  String toString() =>
      'ASV(C:${confidence.toStringAsFixed(2)}, U:${urgency.toStringAsFixed(2)}, S:${stress.toStringAsFixed(2)}, T:${trust.toStringAsFixed(2)}, Q:${curiosity.toStringAsFixed(2)})';
}

/// Emotion Bias ⚡
///
/// Translates AffectiveState into motor-level instructions.
/// Used by the Motor AI to alter motion and execution style.
class EmotionBias {
  final double speedMultiplier;
  final double motionSmoothness;
  final double pauseFrequency;
  final double microAdjustmentGain;
  final String posture; // e.g., 'Stable', 'Retraction', 'Lean-In'
  final String lightColor; // e.g., 'Blue', 'Yellow', 'Red', 'Purple'

  const EmotionBias({
    this.speedMultiplier = 1.0,
    this.motionSmoothness = 1.0,
    this.pauseFrequency = 0.0,
    this.microAdjustmentGain = 1.0,
    this.posture = 'Stable',
    this.lightColor = 'Blue',
  });
}
