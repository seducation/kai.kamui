import '../../services/proactive_alert/machine_abstraction.dart';
import '../../services/proactive_alert/affect_engine.dart';
import '../../services/proactive_alert/affective_state.dart';
import '../../coordination/actuators.dart';

/// Physical World JARVIS Organ: Robot 🦾
class RobotMachine implements Machine {
  @override
  String get id => 'organ_robot_prime';

  @override
  String get name => 'Mark-VII Assembler';

  @override
  DeviceType get type => DeviceType.robot;

  @override
  OrganPriority get priorityLevel => OrganPriority.high;

  @override
  AffectiveState get affectiveState => AffectEngine().getState(id);

  double _jointTorque = 45.0;
  double _lidarDistance = 2.5;
  bool _isEMStop = false;

  @override
  Map<String, dynamic> get sensors => {
        'joint_torque': _jointTorque,
        'lidar_dist': _lidarDistance,
        'emergency_stop': _isEMStop,
      };

  @override
  List<Actuator> get machineActuators => [
        _ServoActuator(this),
      ];

  @override
  SafetyEnvelope get safetyEnvelope => SafetyEnvelope(
        limits: {'joint_torque': 120.0, 'lidar_dist': 0.5},
        description: 'Kinematic & Collision constraints',
      );

  @override
  ControlPolicy get controlPolicy => ControlPolicy(
        mode: 'Stark-Cinematic',
        allowsSelfCorrection: true,
      );

  void simulateObstacle(double distance) {
    _lidarDistance = distance;
  }
}

class _ServoActuator implements Actuator {
  final RobotMachine robot;
  _ServoActuator(this.robot);

  @override
  String get name => 'KinematicServo';

  @override
  Future<ActuatorResult> act(dynamic input) async {
    // 1. Apply Emotion Bias to physical timing
    final bias = AffectEngine().calculateBias(robot.id);
    if (bias.speedMultiplier < 1.0) {
      // Simulate "Strained" or "Careful" motion via latency
      await Future.delayed(Duration(
          milliseconds: (1000 * (1.0 - bias.speedMultiplier)).toInt()));
    }

    if (input == 'REDUCE_TORQUE') {
      robot._jointTorque -= 20.0;
      return ActuatorResult(
          success: true, output: 'Torque reduced for safety.');
    }
    if (input == 'EMERGENCY_HALT') {
      robot._isEMStop = true;
      return ActuatorResult(success: true, output: 'Emergency stop engaged.');
    }
    return ActuatorResult(success: false, error: 'Unknown robot command');
  }
}
