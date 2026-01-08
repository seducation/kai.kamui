import 'dart:async';
import '../../coordination/message_bus.dart';
import '../../coordination/motor_system.dart';
import '../../rules/rule_definitions.dart';
import '../../rules/rule_engine.dart';
import '../speech_gate.dart';
import '../narrator_service.dart';
import 'alert_intent.dart';
import 'machine_abstraction.dart';
import 'affect_engine.dart';

/// Proactive Alert Engine (PAE) 🤖
///
/// Monitors system events, hardware telemetry, and risk forecasts to act proactively.
/// Prioritizes machine manipulation over speech.
class ProactiveAlertEngine {
  static final ProactiveAlertEngine _instance =
      ProactiveAlertEngine._internal();
  factory ProactiveAlertEngine() => _instance;

  ProactiveAlertEngine._internal() {
    _startMonitoring();
  }

  final List<Machine> _machines = [];
  final List<AlertIntent> _activeAlerts = [];

  /// Register a machine for monitoring
  void registerMachine(Machine machine) => _machines.add(machine);

  void _startMonitoring() {
    // 1. Listen for World Events via MessageBus
    messageBus.allMessages.listen((msg) {
      if (msg.type == MessageType.error) {
        _handleError(msg);
      }
    });

    // 2. Periodic Telemetry Check (Every 5 seconds)
    Timer.periodic(const Duration(seconds: 5), (_) => _checkTelemetry());
  }

  void _handleError(AgentMessage msg) {
    // Convert error to AlertIntent
    final alert = AlertIntent(
      id: 'ERR_${DateTime.now().millisecondsSinceEpoch}',
      severity: AlertSeverity.high,
      domain: AlertDomain.security,
      horizon: AlertTimeHorizon.immediate,
      confidence: 1.0,
      description: 'System Reflex: ${msg.payload}',
      vocalizeCandidate: true,
    );

    _processAlert(alert);
  }

  void _checkTelemetry() {
    for (final machine in _machines) {
      final sensors = machine.sensors;
      final envelope = machine.safetyEnvelope;

      // Example: Simple threshold check
      sensors.forEach((key, value) {
        if (envelope.limits.containsKey(key)) {
          final limit = envelope.limits[key];
          if (value is num && limit is num && value > limit) {
            _triggerProactiveIntervention(machine, key, value);
          }
        }
      });
    }
  }

  void _triggerProactiveIntervention(
      Machine machine, String sensorKey, dynamic value) {
    final alert = AlertIntent(
      id: 'TELE_${DateTime.now().millisecondsSinceEpoch}',
      severity: AlertSeverity.high,
      domain: AlertDomain.hardware,
      horizon: AlertTimeHorizon.immediate,
      confidence: 0.95,
      description:
          '${machine.name} sensor "$sensorKey" exceeded limit ($value)',
      recommendedAction: 'ACTUATE_COOLING', // Placeholder
      vocalizeCandidate: true,
    );

    _processAlert(alert);
  }

  Future<void> _processAlert(AlertIntent alert) async {
    _activeAlerts.add(alert);

    // PRINCIPLE: Action First
    if (alert.recommendedAction != null) {
      await _executeRecommendedAction(alert);
    }

    // PRINCIPLE: Silence Costs vs Speech Costs (Handled by SpeechGate)
    if (alert.vocalizeCandidate) {
      // Find the machine associated with this alert if possible
      final machine = _machines.firstWhere(
        (m) => alert.description.contains(m.name),
        orElse: () => _machines.first, // Fallback to first registered
      );

      // 1. Affect AI Integration: Emotion occurs on alert processing
      AffectEngine().processAlertImpact(machine.id, alert);

      final shouldVocalize =
          SpeechGate().evaluateProactiveAlert(alert, machine: machine);
      if (shouldVocalize) {
        narrator.speak(
          alert.description,
          SpeechIntent.proactiveAlert,
          priority:
              alert.isHighRisk ? PriorityLevel.high : PriorityLevel.normal,
        );
      }
    }
  }

  Future<void> _executeRecommendedAction(AlertIntent alert) async {
    // 1. Rule Engine Check (Allowed?)
    final context = RuleContext(
      agentName: 'PAE',
      action: alert.recommendedAction!,
      input: alert.description,
      requestedPriority:
          alert.isHighRisk ? PriorityLevel.high : PriorityLevel.normal,
    );

    final result = RuleEngine().evaluate(context);
    if (result.action == RuleAction.deny) {
      // print('🚫 PAE: Proactive action ${alert.recommendedAction} blocked by Rule Engine.');
      return;
    }

    // 2. Try to find a specific Machine Actuator or connected Connector
    bool actuated = false;
    for (final machine in _machines) {
      // ONLY if AI Control is enabled for this machine
      if (!machine.controlPolicy.isAiControlled) continue;

      // Check if machine has a specific bound connector (e.g., 'AppwriteCloud')
      final boundConnector = machine.controlPolicy.connectedConnectorName;
      if (boundConnector != null) {
        await MotorSystem()
            .execute(boundConnector.toLowerCase(), alert.recommendedAction);
        actuated = true;
        break;
      }

      // Check internal machine actuators
      for (final actuator in machine.machineActuators) {
        final res = await actuator.act(alert.recommendedAction);
        if (res.success) {
          actuated = true;
          break;
        }
      }
      if (actuated) break;
    }

    // 3. Fallback to generic MotorSystem
    if (!actuated) {
      final actuatorKey =
          alert.domain == AlertDomain.hardware ? 'local' : 'cloud';
      await MotorSystem().execute(actuatorKey, alert.recommendedAction);
    }

    // Log the proactive action
    messageBus.broadcast(AgentMessage(
      id: 'proactive_act_${alert.id}',
      from: 'PAE',
      type: MessageType.status,
      payload:
          'PROACTIVE_ACTION: Executed ${alert.recommendedAction} for ${alert.id}',
    ));
  }

  List<AlertIntent> get activeAlerts => List.unmodifiable(_activeAlerts);
  List<Machine> get machines => List.unmodifiable(_machines);
}
