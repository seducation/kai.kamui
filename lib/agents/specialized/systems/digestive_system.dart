import '../../core/step_types.dart';
import '../../core/step_schema.dart';
import '../../coordination/organ_system.dart';
import '../organs/discovery_organ.dart';
import '../organs/logic_organ.dart';
import '../organs/memory_organ.dart';

/// The Digestive System 🧬
///
/// Handles the full lifecycle of information:
/// Ingestion (Discovery) -> Digestion (Logic) -> Absorption (Memory).
class DigestiveSystem extends OrganSystem {
  DigestiveSystem({
    required DiscoveryOrgan discovery,
    required LogicOrgan logic,
    required MemoryOrgan memory,
  }) : super(
          name: 'DigestiveSystem',
          organs: [discovery, logic, memory],
        );

  @override
  Future<R> onRun<R>(dynamic input) async {
    // Phase 1: Ingestion
    final discovery = organs[0] as DiscoveryOrgan;
    final logic = organs[1] as LogicOrgan;
    final memory = organs[2] as MemoryOrgan;

    return await execute<R>(
      action: StepType.analyze,
      target: 'Full knowledge digestion cycle',
      task: () async {
        // Maintain Homeostasis before starting
        await maintainHomeostasis();

        logStatus(
            StepType.fetch, 'Phase 1: Ingesting raw data', StepStatus.running);
        final rawData = await discovery.run<String>(input);

        // Maintain Homeostasis between phases
        await maintainHomeostasis();

        logStatus(StepType.analyze, 'Phase 2: Digesting complex logic',
            StepStatus.running);
        final refinedData = await logic.run<String>(rawData);

        await maintainHomeostasis();

        logStatus(StepType.store, 'Phase 3: Absorbing into long-term memory',
            StepStatus.running);
        await memory.run<bool>({
          'key': 'digested_${DateTime.now().millisecondsSinceEpoch}.json',
          'data': refinedData
        });

        return refinedData as R;
      },
    );
  }
}
