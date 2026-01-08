import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/agents/services/speech_gate.dart';
import 'package:my_app/agents/rules/rule_definitions.dart';
import 'package:my_app/agents/rules/rule_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Volitional Speech Gate Tests', () {
    late SpeechGate gate;

    setUp(() {
      gate = SpeechGate();
      gate.setMissionMode(false);
      RuleEngine().setProfile(ComplianceProfile.personal);
    });

    test('Normal background logs remain silent', () {
      final allowed = gate.evaluateIntent(SpeechIntent.backgroundLog);
      expect(allowed, isFalse);
    });

    test('Access denial triggers safety alert speech', () {
      final allowed = gate.evaluateIntent(SpeechIntent.safetyAlert,
          priority: PriorityLevel.reflex);
      expect(allowed, isTrue);
    });

    test('Mission reports are blocked when Mission Mode is OFF', () {
      gate.setMissionMode(false);
      final allowed = gate.evaluateIntent(SpeechIntent.missionReport);
      expect(allowed, isFalse);
    });

    test(
        'Mission reports are allowed when Mission Mode is ON and priority is sufficient',
        () {
      gate.setMissionMode(true);
      final allowed = gate.evaluateIntent(SpeechIntent.missionReport,
          priority: PriorityLevel.normal);
      expect(allowed, isTrue);
    });

    test('Direct responses are always allowed', () {
      final allowed = gate.evaluateIntent(SpeechIntent.directResponse);
      expect(allowed, isTrue);
    });

    test('System stays silent in Operator Mode', () {
      RuleEngine().setProfile(ComplianceProfile.operator);
      final allowed = gate.evaluateIntent(SpeechIntent.safetyAlert,
          priority: PriorityLevel.reflex);
      expect(allowed, isFalse);
    });

    test('Rule with vocalize=true triggers speech evaluation', () async {
      final rule = Rule(
        id: 'VOICE-TEST',
        type: RuleType.safety,
        scope: RuleScope.global,
        condition: 'contains: "trigger"',
        action: RuleAction.deny,
        explanation: 'Testing vocal logic',
        vocalize: true,
      );

      await RuleEngine().addRule(rule);

      final context = RuleContext(
        agentName: 'TestAgent',
        action: 'execute',
        input: 'trigger',
        requestedPriority: PriorityLevel.normal,
      );

      // We can't easily capture the Narrator.speak call in a light test,
      // but we can verify the rule matches and that evaluateIntent would allow it.
      final result = RuleEngine().evaluate(context);
      expect(result.triggeringRule?.id, equals('VOICE-TEST'));
      expect(result.triggeringRule?.vocalize, isTrue);

      // The evaluate() call now triggers speech internally.
      // We've verified the state is correct for the trigger.
    });
  });
}
