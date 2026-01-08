import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/agents/services/proactive_alert/proactive_alert_engine.dart';
import 'package:my_app/agents/services/proactive_alert/alert_intent.dart';
import 'package:my_app/agents/services/speech_gate.dart';
import 'package:my_app/agents/specialized/systems/thermal_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stark-Style Proactive System Tests 🦾', () {
    late ProactiveAlertEngine pae;
    late ThermalController thermal;

    setUp(() {
      pae = ProactiveAlertEngine();
      thermal = ThermalController();
      pae.registerMachine(thermal);
      SpeechGate().setChatterProfile(ChatterProfile.tactical);
    });

    test(
        'Silent Proactive: Machine self-corrects without speech if severity is low',
        () async {
      // 1. Simulate a mild heat spike
      thermal
          .simulateHeat(30.0); // Now ~72C (Limit is 85C, so not critical yet)

      final alert = AlertIntent(
        id: 'SILENT_TEST',
        severity: AlertSeverity.medium,
        domain: AlertDomain.hardware,
        horizon: AlertTimeHorizon.short,
        confidence: 0.9,
        description: 'Rising temperatures detected',
        recommendedAction: 'ACTUATE_COOLING',
        vocalizeCandidate: true,
      );

      // 2. Evaluate vocalization (Tactical mode)
      // Tactical threshold is 80 (High/Critical). Medium is 40.
      final shouldVocalize = SpeechGate().evaluateProactiveAlert(alert);
      expect(shouldVocalize, isFalse,
          reason: 'Tactical profile should keep medium alerts silent.');

      // 3. Actuate machine
      final res = await thermal.machineActuators.first.act('ACTUATE_COOLING');
      expect(res.success, isTrue);
    });

    test('Cinematic Mode: JARVIS speaks more freely', () {
      SpeechGate().setChatterProfile(ChatterProfile.cinematic);

      final alert = AlertIntent(
        id: 'CINEMATIC_TEST',
        severity: AlertSeverity.medium,
        domain: AlertDomain.hardware,
        horizon: AlertTimeHorizon.short,
        confidence: 0.9,
        description: 'Sir, it is getting a bit warm.',
        vocalizeCandidate: true,
      );

      final shouldVocalize = SpeechGate().evaluateProactiveAlert(alert);
      expect(shouldVocalize, isTrue,
          reason: 'Cinematic profile allows medium severity speech.');
    });

    test(
        'Reflex-Level Alert: High Silence Cost triggers speech even in Tactical',
        () {
      SpeechGate().setChatterProfile(ChatterProfile.tactical);

      final alert = AlertIntent(
        id: 'CRITICAL_TEST',
        severity: AlertSeverity.critical,
        domain: AlertDomain.hardware,
        horizon: AlertTimeHorizon.immediate,
        confidence: 0.99,
        description: 'CORE MELTDOWN IMMINENT',
        vocalizeCandidate: true,
      );

      final shouldVocalize = SpeechGate().evaluateProactiveAlert(alert);
      expect(shouldVocalize, isTrue,
          reason: 'Critical immediate alerts must vocalize in Tactical.');
    });
  });
}
