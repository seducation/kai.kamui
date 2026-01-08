import '../core/agent_base.dart';
import '../core/step_types.dart';
import '../services/proactive_alert/proactive_alert_engine.dart';

/// The Organ Agent 🩺🦾
///
/// Allows the system to query the status of its "Organs" (Machines).
/// It provides a cognitive interface to the Proactive Alert Engine.
class OrganAgent extends AgentBase {
  final ProactiveAlertEngine _pae = ProactiveAlertEngine();

  OrganAgent({super.logger}) : super(name: 'OrganMonitor');

  @override
  Future<R> onRun<R>(dynamic input) async {
    final query = input.toString().toLowerCase();

    if (query.contains('status') || query.contains('list')) {
      return await _reportStatus() as R;
    }

    if (query.contains('check')) {
      return await _checkSpecificOrgan(query) as R;
    }

    return 'I can check the status of your organs (Robots, Servers, Phones). Try asking for "organ status".'
        as R;
  }

  Future<String> _reportStatus() async {
    return await execute<String>(
      action: StepType.analyze,
      target: 'scanning all system organs',
      task: () async {
        final machines = _pae.machines;
        if (machines.isEmpty) return 'No organs registered in DOI.';

        final report = machines.map((m) {
          final typeStr = m.type.name.toUpperCase();
          return '- [${m.name}] ($typeStr): ${m.sensors}';
        }).join('\n');

        return 'System Organ Report:\n$report';
      },
    );
  }

  Future<String> _checkSpecificOrgan(String query) async {
    return await execute<String>(
      action: StepType.analyze,
      target: 'checking specific organ telemetry',
      task: () async {
        final machine = _pae.machines.firstWhere(
          (m) =>
              query.contains(m.name.toLowerCase()) ||
              query.contains(m.type.name),
          orElse: () => _pae.machines.first,
        );

        return 'Organ Status: ${machine.name}\nSensors: ${machine.sensors}\nControl: ${machine.controlPolicy.mode}\nAI Control: ${machine.controlPolicy.isAiControlled ? "ACTIVE" : "DISABLED"}';
      },
    );
  }
}
