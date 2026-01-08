import '../../services/proactive_alert/machine_abstraction.dart';
import '../../services/proactive_alert/affect_engine.dart';
import '../../services/proactive_alert/affective_state.dart';
import '../../coordination/actuators.dart';

/// Sensory + Interface Organ: Phone 📱
class PhoneMachine implements Machine {
  @override
  String get id => 'organ_phone_stark';

  @override
  String get name => 'Stark Mobile Interface';

  @override
  DeviceType get type => DeviceType.phone;

  @override
  OrganPriority get priorityLevel => OrganPriority.normal;

  @override
  AffectiveState get affectiveState => AffectEngine().getState(id);

  int _batteryLevel = 18;
  bool _isBackgroundRefresh = true;

  @override
  Map<String, dynamic> get sensors => {
        'battery': _batteryLevel,
        'background_refresh': _isBackgroundRefresh,
        'signal_strength': 'Optimal',
      };

  @override
  List<Actuator> get machineActuators => [
        _PhoneUiActuator(this),
      ];

  @override
  SafetyEnvelope get safetyEnvelope => SafetyEnvelope(
        limits: {'battery': 15}, // Threshold for power saving
        description: 'Power preservation limits',
      );

  @override
  ControlPolicy get controlPolicy => ControlPolicy(
        mode: 'Silent',
        allowsSelfCorrection: true,
      );

  void simulateDrain(int amount) {
    _batteryLevel -= amount;
  }
}

class _PhoneUiActuator implements Actuator {
  final PhoneMachine phone;
  _PhoneUiActuator(this.phone);

  @override
  String get name => 'NexusInterface';

  @override
  Future<ActuatorResult> act(dynamic input) async {
    // 1. Affective modulation: Hesitation / Caution bias
    final bias = AffectEngine().calculateBias(phone.id);
    if (bias.pauseFrequency > 0.1) {
      await Future.delayed(
          Duration(milliseconds: (bias.pauseFrequency * 500).toInt()));
    }

    if (input == 'POWER_SAVE_MODE') {
      phone._isBackgroundRefresh = false;
      return ActuatorResult(
          success: true, output: 'Conservation mode engaged.');
    }
    return ActuatorResult(success: false, error: 'Unknown phone command');
  }
}
