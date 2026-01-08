import 'dart:async';
import 'dart:math';
import '../../coordination/message_bus.dart';
import 'thermal_controller.dart';

/// A "Stress Testing" AI Agent 🏗️
///
/// Simulates a second AI that causes system load or uses machinery incorrectly,
/// allowing us to see the PAE (JARVIS) correct it autonomously.
class SimulationAgent {
  final ThermalController thermal;
  Timer? _timer;
  final _random = Random();

  SimulationAgent(this.thermal);

  void start() {
    // print('🧪 SimulationAgent: Starting system stress patterns...');
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _simulateActivity();
    });
  }

  void stop() {
    _timer?.cancel();
  }

  void _simulateActivity() {
    final action = _random.nextInt(3);

    switch (action) {
      case 0:
        // Simulate a "Workload Spike" (Heat goes up)
        thermal.simulateHeat(15.0);
        messageBus.broadcast(AgentMessage(
          id: 'sim_spike_${DateTime.now().millisecondsSinceEpoch}',
          from: 'SimulationAgent',
          type: MessageType.status,
          payload: 'Simulating high-compute workload. Thermal load increasing.',
        ));
        break;
      case 1:
        // Simulate a "Machine Misuse" (Triggers a rule violation)
        messageBus.broadcast(AgentMessage(
          id: 'sim_error_${DateTime.now().millisecondsSinceEpoch}',
          from: 'SimulationAgent',
          type: MessageType.error,
          payload: 'Accessing restricted actuator without proper token.',
        ));
        break;
      case 2:
        // Just a status update
        messageBus.broadcast(AgentMessage(
          id: 'sim_idle_${DateTime.now().millisecondsSinceEpoch}',
          from: 'SimulationAgent',
          type: MessageType.status,
          payload: 'Optimizing background processes.',
        ));
        break;
    }
  }
}
