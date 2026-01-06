import '../../core/step_types.dart';
import '../../core/step_schema.dart';
import '../../coordination/organ_base.dart';
import '../../specialized/code_writer_agent.dart';
import '../../specialized/code_debugger_agent.dart';
import '../../specialized/diff_agent.dart';

/// The Logic Organ 🫀
///
/// Coordinates CodeWriter, Debugger, and Diff agents to ensure
/// code is not just written, but verified and corrected.
class LogicOrgan extends Organ {
  LogicOrgan({
    required CodeWriterAgent writer,
    required CodeDebuggerAgent debugger,
    required DiffAgent differ,
  }) : super(
          name: 'LogicOrgan',
          tissues: [writer, debugger, differ],
          tokenLimit: 50000,
        );

  @override
  Future<R> onRun<R>(dynamic input) async {
    if (health < 0.3) {
      throw Exception('Logic Organ is fatigued. Needs rest.');
    }

    final writer = tissues[0] as CodeWriterAgent;
    final debugger = tissues[1] as CodeDebuggerAgent;

    // Cycle: Write -> Debug -> Correct
    return await execute<R>(
      action: StepType.analyze,
      target: 'Self-healing logic cycle',
      task: () async {
        // 1. Initial Write
        logStatus(
            StepType.modify, 'Generating initial logic', StepStatus.running);
        final initialCode = await writer.run<String>(input);
        consumeMetabolite(initialCode.length);

        // 2. Debug/Validate
        logStatus(
            StepType.check, 'Validating logic integrity', StepStatus.running);
        final debugResult = await debugger.run<String>(initialCode);
        consumeMetabolite(500);

        if (debugResult.contains('error') || debugResult.contains('bug')) {
          logStatus(StepType.modify, 'Correcting detected anomalies',
              StepStatus.running);
          final fixedCode = await writer.run<String>(
              'Fix this code based on these errors: $debugResult\nCode: $initialCode');
          consumeMetabolite(fixedCode.length);
          return fixedCode as R;
        }

        return initialCode as R;
      },
    );
  }
}
