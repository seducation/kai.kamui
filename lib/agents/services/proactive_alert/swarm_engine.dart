import 'dart:async';
import 'dart:math';
import 'affect_engine.dart';
import 'swarm_affect.dart';
import 'proactive_alert_engine.dart';

/// Swarm Engine: Orchestrates Collective Affect & Mode 🐝🧠
///
/// Aggregates individual organ states into swarm-level behavior.
class SwarmEngine {
  static final SwarmEngine _instance = SwarmEngine._internal();
  factory SwarmEngine() => _instance;
  SwarmEngine._internal() {
    _startPropagationLoop();
  }

  void _startPropagationLoop() {
    Timer.periodic(const Duration(seconds: 5), (_) => propagateAffect());
  }

  final AffectEngine _affectEngine = AffectEngine();
  final ProactiveAlertEngine _pae = ProactiveAlertEngine();

  /// Calculates the current global swarm state
  SwarmAffect calculateSwarmAffect() {
    final machines = _pae.machines;
    if (machines.isEmpty) {
      return const SwarmAffect(
        meanStress: 0.0,
        varianceStress: 0.0,
        meanConfidence: 1.0,
        meanUrgency: 0.0,
        meanCuriosity: 0.0,
        coherence: 1.0,
        dominantMode: SwarmMode.calm,
      );
    }

    double sumStress = 0.0;
    double sumConf = 0.0;
    double sumUrg = 0.0;
    double sumCurMode = 0.0;

    for (final m in machines) {
      final s = m.affectiveState;
      sumStress += s.stress;
      sumConf += s.confidence;
      sumUrg += s.urgency;
      sumCurMode += s.curiosity;
    }

    final meanStress = sumStress / machines.length;
    final meanConf = sumConf / machines.length;
    final meanUrg = sumUrg / machines.length;
    final meanCuriosity = sumCurMode / machines.length;

    // Calculate Variance (Jitter)
    double varStress = 0.0;
    for (final m in machines) {
      varStress += pow(m.affectiveState.stress - meanStress, 2);
    }
    varStress /= machines.length;

    // Calculate Coherence (Alignment of states)
    // For now, simplicity: reciprocal of stress variance
    final coherence = (1.0 - (varStress * 5)).clamp(0.0, 1.0);

    // Determine Mode
    SwarmMode mode = SwarmMode.calm;
    if (meanStress > 0.6) {
      mode = SwarmMode.defensive;
    } else if (varStress > 0.1) {
      mode = SwarmMode.alert;
    } else if (meanConf > 0.8 && meanStress < 0.2) {
      mode = SwarmMode.flow;
    } else if (meanCuriosity > 0.5) {
      mode = SwarmMode.explore;
    } else if (meanUrg > 0.5) {
      mode = SwarmMode.alert; // Or emergency mode
    }

    return SwarmAffect(
      meanStress: meanStress,
      varianceStress: varStress,
      meanConfidence: meanConf,
      meanUrgency: meanUrg,
      meanCuriosity: meanCuriosity,
      coherence: coherence,
      dominantMode: mode,
    );
  }

  /// Propagates stress between 'neighbors' (Sequential list propagation)
  ///
  /// Rule: Local only. Agents change toward neighbor stress but dampened.
  void propagateAffect() {
    final machines = _pae.machines;
    if (machines.length < 2) return;

    for (int i = 0; i < machines.length; i++) {
      final prev = machines[i == 0 ? machines.length - 1 : i - 1];
      final next = machines[(i + 1) % machines.length];

      final currentMachine = machines[i];
      final currentS = currentMachine.affectiveState;
      final neighborAvgStress =
          (prev.affectiveState.stress + next.affectiveState.stress) / 2;

      // Dampened adjustment
      final delta = (neighborAvgStress - currentS.stress).clamp(-0.05, 0.05);

      // We need a way to update the state back in AffectEngine
      // This is a "propagation" update
      final propagatedState = currentS.copyWith(
        stress: (currentS.stress + delta).clamp(0.0, 1.0),
      );

      // Update the affect engine with the new propagated state
      // (Bypassing alert processing, just direct state modulation)
      _affectEngine.forceUpdateState(currentMachine.id, propagatedState);
    }
  }
}
