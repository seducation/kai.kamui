/// Swarm Operational Modes 🐝
///
/// Implicit macro-behaviors triggered by aggregate affect.
enum SwarmMode {
  calm, // Low stress, high trust (Default)
  flow, // Low stress + high confidence (High performant)
  alert, // Rising stress variance/instability
  defensive, // High mean stress (Safety priority)
  explore, // High curiosity + low urgency
  recovery, // Sustained high stress cooldown
}

/// Swarm Affect Vector (Aggregate) 📊
///
/// Represents the collective 'emotional' state of all connected organs.
class SwarmAffect {
  final double meanStress;
  final double varianceStress; // Jitter/Instability
  final double meanConfidence;
  final double meanUrgency;
  final double meanCuriosity;
  final double coherence; // 0-1 (How aligned are the agents?)
  final SwarmMode dominantMode;

  const SwarmAffect({
    required this.meanStress,
    required this.varianceStress,
    required this.meanConfidence,
    required this.meanUrgency,
    required this.meanCuriosity,
    required this.coherence,
    required this.dominantMode,
  });

  @override
  String toString() =>
      'SwarmAffect(Mode: ${dominantMode.name}, Stress: ${meanStress.toStringAsFixed(2)}, Coherence: ${coherence.toStringAsFixed(2)})';
}
