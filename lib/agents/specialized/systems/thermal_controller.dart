import '../../services/proactive_alert/machine_abstraction.dart';
import '../../services/proactive_alert/affect_engine.dart';
import '../../services/proactive_alert/affective_state.dart';
import '../../coordination/actuators.dart';

/// An example Machine implementation for Hardware Control.
class ThermalController implements Machine {
  @override
  String get id => 'organ_thermal_01';

  @override
  String get name => 'ThermalController';

  @override
  DeviceType get type => DeviceType.server;

  @override
  OrganPriority get priorityLevel => OrganPriority.normal;

  @override
  AffectiveState get affectiveState => AffectEngine().getState(id);

  double _currentTemp = 42.0;
  double _fanSpeed = 1500.0;

  @override
  Map<String, dynamic> get sensors => {
        'temperature': _currentTemp,
        'fan_speed': _fanSpeed,
      };

  @override
  List<Actuator> get machineActuators => [
        _FanActuator(this),
      ];

  @override
  SafetyEnvelope get safetyEnvelope => SafetyEnvelope(
        limits: {'temperature': 85.0}, // Shutdown / Critical at 85C
        description: 'Hardware thermal limits',
      );

  @override
  ControlPolicy get controlPolicy => ControlPolicy(
        mode: 'Tactical',
        allowsSelfCorrection: true,
      );

  /// Simulate temperature hike for testing
  void simulateHeat(double amount) => _currentTemp += amount;
}

class _FanActuator implements Actuator {
  final ThermalController controller;
  _FanActuator(this.controller);

  @override
  String get name => 'SystemFan';

  @override
  Future<ActuatorResult> act(dynamic input) async {
    // 1. Affective modulation of fan response
    final bias = AffectEngine().calculateBias(controller.id);

    if (input == 'BOOST_FANS' || input == 'ACTUATE_COOLING') {
      controller._fanSpeed =
          (controller._fanSpeed + (500 * bias.speedMultiplier))
              .clamp(0.0, 10000.0);
      controller._currentTemp -= (2.0 * bias.speedMultiplier);
      return ActuatorResult(
          success: true,
          output:
              'Fans boosted to ${controller._fanSpeed.toInt()} RPM (Bias: ${bias.speedMultiplier}x).');
    }
    if (input == 'QUIET_MODE') {
      controller._fanSpeed = 800.0;
      return ActuatorResult(
          success: true, output: 'Power-save cooling engaged.');
    }
    return ActuatorResult(success: false, error: 'Unknown thermal command');
  }
}
