import '../../coordination/actuators.dart';
import 'affective_state.dart';

/// One rule: All devices are treated as "organs", not tools.
/// They have senses, muscles, limits, and reflexes.

enum DeviceType { robot, server, phone }

enum OrganPriority { reflex, emergency, high, normal, maintenance }

/// Device Organ Interface (DOI) 🦾
///
/// Defines a hardware or system component that acts as a JARVIS "Organ".
abstract class Machine {
  String get id;
  String get name;
  DeviceType get type;

  /// Current telemetry/sensor data (Senses)
  Map<String, dynamic> get sensors;

  /// Available actuators for this machine (Muscles)
  List<Actuator> get machineActuators;

  /// The safety boundaries for this machine (Limits)
  SafetyEnvelope get safetyEnvelope;

  /// The autonomous control policy
  ControlPolicy get controlPolicy;

  /// Underlying priority level of this organ
  OrganPriority get priorityLevel;

  /// NEW: The math-driven behavioral affect (Emotion Vector)
  AffectiveState get affectiveState;
}

/// Safety boundaries to prevent "Machine" damage
class SafetyEnvelope {
  final Map<String, dynamic> limits;
  final String description;

  SafetyEnvelope({required this.limits, required this.description});
}

/// Determines how a machine reacts to sensor spikes autonomously
class ControlPolicy {
  String mode; // e.g., 'Aggressive', 'Economic', 'Silent'
  bool allowsSelfCorrection;
  bool isAiControlled; // Whether JARVIS can act autonomously
  String? connectedConnectorName; // Bind to a MotorSystem actuator

  ControlPolicy({
    required this.mode,
    this.allowsSelfCorrection = true,
    this.isAiControlled = true,
    this.connectedConnectorName,
  });
}
