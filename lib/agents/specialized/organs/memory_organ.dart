import '../../core/step_types.dart';
import '../../core/step_schema.dart';
import '../../coordination/organ_base.dart';
import '../../specialized/storage_agent.dart';
import '../../coordination/reliability_tracker.dart';

/// The Memory Organ 🫀
///
/// Coordinates Storage, Performance Memory (Reliability), and Audit Lineage.
class MemoryOrgan extends Organ {
  MemoryOrgan({
    required StorageAgent storage,
    required ReliabilityTracker reliability,
  }) : super(
          name: 'MemoryOrgan',
          tissues: [
            storage
          ], // Reliability is a singleton but tracked as tissue concept
          tokenLimit: 20000,
        );

  @override
  Future<R> onRun<R>(dynamic input) async {
    final storage = tissues[0] as StorageAgent;

    return await execute<R>(
      action: StepType.store,
      target: 'Deep memory persistence',
      task: () async {
        logStatus(StepType.store, 'Encoding information into vault',
            StepStatus.running);

        // Input: {'key': '...', 'data': '...'}
        if (input is Map<String, dynamic>) {
          final key = input['key'] ??
              'memory_${DateTime.now().millisecondsSinceEpoch}.json';
          final data = input['data'];

          await storage.save(key, data, requester: 'MemoryOrgan');
          consumeMetabolite(100);
          return true as R;
        }

        throw ArgumentError('MemoryOrgan expects Map input');
      },
    );
  }
}
