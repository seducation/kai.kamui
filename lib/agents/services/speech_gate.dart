import '../coordination/autonomic_system.dart';
import '../specialized/systems/user_context.dart';
import '../rules/rule_engine.dart';
import '../rules/rule_definitions.dart';
import '../coordination/message_bus.dart';
import 'proactive_alert/alert_intent.dart';
import 'proactive_alert/machine_abstraction.dart';

/// Why the system wants to speak.
enum SpeechIntent {
  /// A critical rule was violated or a dangerous action blocked.
  safetyAlert,

  /// System health or stability has changed significantly.
  healthUpdate,

  /// Periodic report during an active mission.
  missionReport,

  /// Response to a direct user question (Always allowed).
  directResponse,

  /// Low-priority background chatter (Usually blocked).
  backgroundLog,

  /// A proactive alert from the PAE
  proactiveAlert,
}

/// A rule that governs whether a specific intent is allowed to speak.
class SpeechRule {
  final bool Function(SpeechIntent intent, SystemHealth health,
      UserContext context, int priority) condition;
  final String description;

  const SpeechRule({required this.condition, required this.description});
}

/// The Volitional Speech Gate 2.0 🔊
///
/// Prevents the system from speaking unless specific, intentional conditions are met.
/// Implements Tony Stark-style "Silence Cost vs Speech Cost" logic.
class SpeechGate {
  static final SpeechGate _instance = SpeechGate._internal();
  factory SpeechGate() => _instance;
  SpeechGate._internal() {
    _initListener();
  }

  bool _isMissionMode = false;
  ChatterProfile _currentProfile = ChatterProfile.tactical;

  /// Enable or disable Mission Mode.
  void setMissionMode(bool enabled) => _isMissionMode = enabled;
  bool get isMissionMode => _isMissionMode;

  /// Set the current chatter profile (Silent, Tactical, Assistive, Cinematic)
  void setChatterProfile(ChatterProfile profile) => _currentProfile = profile;
  ChatterProfile get currentProfile => _currentProfile;

  /// Initialize system-wide listener for critical events
  void _initListener() {
    messageBus.allMessages.listen((msg) {
      if (msg.type == MessageType.error) {
        evaluateIntent(SpeechIntent.safetyAlert,
            priority: PriorityLevel.critical);
      }
    });
  }

  /// Evaluate if a proactive alert should vocalize
  bool evaluateProactiveAlert(AlertIntent alert, {Machine? machine}) {
    if (_currentProfile == ChatterProfile.silent) return false;

    final severityMap = {
      AlertSeverity.low: 20,
      AlertSeverity.medium: 40,
      AlertSeverity.high: 70,
      AlertSeverity.critical: 90,
    };

    final severityScore = severityMap[alert.severity] ?? 0;

    // Formula: (severity >= threshold) AND (confidence >= threshold)
    double vocalThreshold = 0.8;
    int severityThreshold = 60; // Default: Only High/Critical

    if (_currentProfile == ChatterProfile.cinematic) {
      vocalThreshold = 0.5;
      severityThreshold = 30;
    } else if (_currentProfile == ChatterProfile.tactical) {
      vocalThreshold = 0.9;
      severityThreshold = 80;
    }

    final passesThresholds = severityScore >= severityThreshold &&
        alert.confidence >= vocalThreshold;

    if (!passesThresholds) return false;

    // Stark Principle: Silence Cost > Speech Cost
    final silenceCost = _calculateSilenceCost(alert, machine: machine);
    final speechCost = _calculateSpeechCost(machine: machine);

    // Rule: Phone never initiates long speech
    if (machine?.type == DeviceType.phone &&
        _currentProfile != ChatterProfile.cinematic) {
      // Phones only confirm/warn/acknowledge (represented by high cost of long speech)
      vocalThreshold = 0.95;
    }

    return alert.vocalizeCandidate && (silenceCost > speechCost);
  }

  double _calculateSilenceCost(AlertIntent alert, {Machine? machine}) {
    double cost = 0.0;
    // Immediate time horizon has high silence cost
    if (alert.horizon == AlertTimeHorizon.immediate) cost += 0.5;

    // Physical danger (Robot) has extremely high silence cost
    if (machine?.type == DeviceType.robot) cost += 0.3;

    // Security/Hardware domains have high silence cost
    if (alert.domain == AlertDomain.security ||
        alert.domain == AlertDomain.hardware) {
      cost += 0.4;
    }

    // High severity increases cost
    if (alert.severity == AlertSeverity.critical) cost += 0.5;

    return cost.clamp(0.0, 1.0);
  }

  double _calculateSpeechCost({Machine? machine}) {
    final context = UserContext();
    double cost = 0.2; // Base cost of talking

    // Phone speech cost is slightly lower for short warnings
    if (machine?.type == DeviceType.phone) cost -= 0.1;

    // If user is busy or frustrated, speech cost is higher
    if (context.mood == UserMood.busy) cost += 0.5;
    if (context.mood == UserMood.frustrated) cost += 0.3;

    return cost.clamp(0.0, 1.0);
  }

  final List<SpeechRule> _rules = [
    SpeechRule(
      description: 'Allow direct responses',
      condition: (intent, _, __, ___) => intent == SpeechIntent.directResponse,
    ),
    SpeechRule(
      description: 'Allow safety alerts except in Operator Mode',
      condition: (intent, _, __, ___) =>
          intent == SpeechIntent.safetyAlert &&
          RuleEngine().activeProfile != ComplianceProfile.operator,
    ),
    SpeechRule(
      description: 'Allow critical health updates',
      condition: (intent, health, _, __) =>
          intent == SpeechIntent.healthUpdate &&
          health == SystemHealth.critical,
    ),
    SpeechRule(
      description: 'Allow mission reports in Mission Mode',
      condition: (intent, _, __, p) =>
          intent == SpeechIntent.missionReport &&
          SpeechGate().isMissionMode &&
          p >= PriorityLevel.normal,
    ),
  ];

  /// Evaluate if a standard speech intent is allowed to proceed.
  bool evaluateIntent(SpeechIntent intent,
      {int priority = PriorityLevel.normal}) {
    if (_currentProfile == ChatterProfile.silent) return false;

    final health = AutonomicSystem().currentHealth;
    final context = UserContext();

    if (RuleEngine().activeProfile == ComplianceProfile.operator) {
      return false;
    }

    for (final rule in _rules) {
      if (rule.condition(intent, health, context, priority)) {
        return true;
      }
    }

    return false;
  }
}
