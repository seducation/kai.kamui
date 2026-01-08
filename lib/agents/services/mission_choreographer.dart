import 'dart:async';
import '../services/proactive_alert/proactive_alert_engine.dart';
import '../services/narrator_service.dart';
import '../services/speech_gate.dart';
import '../rules/rule_definitions.dart';

/// One step in a multi-device choreography
class ChoreographyStep {
  final String organId;
  final String command;
  final Duration delay;
  final String description;

  ChoreographyStep({
    required this.organId,
    required this.command,
    this.delay = Duration.zero,
    required this.description,
  });
}

/// Orchestrates Cross-Device Missions (Robot + Server + Phone) 🎭🦾
class MissionChoreographer {
  static final MissionChoreographer _instance =
      MissionChoreographer._internal();
  factory MissionChoreographer() => _instance;
  MissionChoreographer._internal();

  final ProactiveAlertEngine _pae = ProactiveAlertEngine();

  Future<void> beginDeepComputeMission() async {
    final steps = [
      ChoreographyStep(
        organId: 'organ_phone_stark',
        command: 'POWER_SAVE_MODE',
        description: 'Battery preservation engaged for high-load task.',
      ),
      ChoreographyStep(
        organId: 'organ_thermal_01',
        command: 'BOOST_FAN',
        delay: const Duration(seconds: 1),
        description: 'Pre-emptive cooling for compute spike.',
      ),
      ChoreographyStep(
        organId: 'organ_robot_prime',
        command: 'REDUCE_TORQUE',
        delay: const Duration(seconds: 2),
        description: 'Slowing kinemantics to prioritize compute resources.',
      ),
    ];

    await executeMission('Deep Compute Synchronization', steps);
  }

  Future<void> executeMission(String name, List<ChoreographyStep> steps) async {
    // print('🎬 MISSION START: $name');
    narrator.speak(
      "Beginning mission choreography: $name.",
      SpeechIntent.missionReport,
      priority: PriorityLevel.high,
    );

    for (final step in steps) {
      if (step.delay > Duration.zero) {
        await Future.delayed(step.delay);
      }

      final organ = _pae.machines.firstWhere(
        (m) => m.id == step.organId,
        orElse: () => _pae.machines.first,
      );

      // print('⚡ Acting on ${organ.name}: ${step.command}');
      for (final actuator in organ.machineActuators) {
        await actuator.act(step.command);
      }

      // Briefly report mission status
      narrator.speak(
        step.description,
        SpeechIntent.missionReport,
        priority: PriorityLevel.normal,
      );
    }

    narrator.speak(
      "Mission $name complete. All organs synchronized.",
      SpeechIntent.missionReport,
      priority: PriorityLevel.normal,
    );
  }
}
