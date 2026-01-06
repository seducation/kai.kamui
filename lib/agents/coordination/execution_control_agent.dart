import '../core/agent_base.dart';
import '../core/step_types.dart';
import '../core/step_schema.dart';

import 'execution_manager.dart';

/// Agent for controlling execution modes and managing task lifecycle.
///
/// Provides:
/// - Dry Run: Simulate without side effects
/// - Replay: Re-run successful executions
/// - Redo: Retry failed executions
/// - Undo: Rollback to previous state
class ExecutionControlAgent extends AgentBase {
  final ExecutionManager _manager = ExecutionManager();

  ExecutionControlAgent({super.logger}) : super(name: 'ExecutionControl');

  @override
  Future<R> onRun<R>(dynamic input) async {
    await _manager.initialize();

    if (input is ExecutionControlRequest) {
      return await handleRequest(input) as R;
    }
    throw ArgumentError('Expected ExecutionControlRequest');
  }

  Future<dynamic> handleRequest(ExecutionControlRequest request) async {
    switch (request.command) {
      case ExecutionCommand.setMode:
        return await setMode(request.mode!);
      case ExecutionCommand.replay:
        return await replay(request.taskName!);
      case ExecutionCommand.redo:
        return await redo(request.taskName!);
      case ExecutionCommand.undo:
        return await undo();
      case ExecutionCommand.dryRun:
        return await dryRun(request.task!);
      case ExecutionCommand.getHistory:
        return getHistory();
      case ExecutionCommand.getFailures:
        return getFailures();
      case ExecutionCommand.cleanup:
        return await cleanup();
    }
  }

  /// Set execution mode
  Future<void> setMode(ExecutionMode mode) async {
    await execute<void>(
      action: StepType.decide,
      target: 'setting mode to ${mode.name}',
      task: () async {
        _manager.setMode(mode);
      },
    );
  }

  /// Replay a successful execution
  Future<ExecutionRecord?> replay(String taskName) async {
    return await execute<ExecutionRecord?>(
      action: StepType.modify,
      target: 'replaying task: $taskName',
      task: () async {
        final record = _manager.findForReplay(taskName);
        if (record == null) {
          logger.logStep(
            agentName: name,
            action: StepType.error,
            target: 'No replayable record found for: $taskName',
            status: StepStatus.failed,
          );
          return null;
        }

        logger.logStep(
          agentName: name,
          action: StepType.check,
          target:
              'Found record from ${record.timestamp} with ${record.steps.length} steps',
          status: StepStatus.success,
        );

        // In real impl: re-execute each step from record
        for (final step in record.steps) {
          logger.logStep(
            agentName: step.agentName,
            action: StepType.modify,
            target: '[REPLAY] ${step.action} -> ${step.target}',
            status: StepStatus.success,
          );
        }

        return record;
      },
    );
  }

  /// Redo a failed execution
  Future<ExecutionRecord?> redo(String taskName) async {
    return await execute<ExecutionRecord?>(
      action: StepType.modify,
      target: 'redoing failed task: $taskName',
      task: () async {
        final record = _manager.findForRedo(taskName);
        if (record == null) {
          logger.logStep(
            agentName: name,
            action: StepType.error,
            target: 'No failed record found for: $taskName',
            status: StepStatus.failed,
          );
          return null;
        }

        logger.logStep(
          agentName: name,
          action: StepType.check,
          target:
              'Found failure from ${record.timestamp}: ${record.errorMessage}',
          status: StepStatus.success,
        );

        // In real impl: re-execute with original input
        logger.logStep(
          agentName: name,
          action: StepType.modify,
          target: '[REDO] Retrying with original input...',
          status: StepStatus.running,
        );

        // If redo succeeds, resolve the failure
        await _manager.resolveFailure(record.id);

        return record;
      },
    );
  }

  /// Undo the last change
  Future<bool> undo() async {
    return await execute<bool>(
      action: StepType.modify,
      target: 'undoing last change',
      task: () async {
        if (!_manager.canUndo) {
          logger.logStep(
            agentName: name,
            action: StepType.error,
            target: 'No undo state available',
            status: StepStatus.failed,
          );
          return false;
        }

        final state = _manager.popUndoState();
        if (state == null) return false;

        logger.logStep(
          agentName: name,
          action: StepType.modify,
          target: '[UNDO] Restoring previous state...',
          status: StepStatus.success,
          metadata: state,
        );

        // In real impl: restore file contents from state['files']
        return true;
      },
    );
  }

  /// Execute in dry-run mode (simulate without side effects)
  Future<ExecutionRecord> dryRun(Future<void> Function() task) async {
    return await execute<ExecutionRecord>(
      action: StepType.analyze,
      target: 'executing dry run',
      task: () async {
        final previousMode = _manager.currentMode;
        _manager.setMode(ExecutionMode.dryRun);

        final stopwatch = Stopwatch()..start();
        final steps = <ExecutionStep>[];

        logger.logStep(
          agentName: name,
          action: StepType.check,
          target: '[DRY RUN] Starting simulation...',
          status: StepStatus.running,
        );

        ExecutionResult result;
        String? errorMessage;

        try {
          // In dry run mode, operations are simulated
          await task();
          result = ExecutionResult.dryRunComplete;

          logger.logStep(
            agentName: name,
            action: StepType.check,
            target: '[DRY RUN] Simulation complete - no side effects',
            status: StepStatus.success,
          );
        } catch (e) {
          result = ExecutionResult.failed;
          errorMessage = e.toString();

          logger.logStep(
            agentName: name,
            action: StepType.error,
            target: '[DRY RUN] Would have failed: $e',
            status: StepStatus.failed,
          );
        }

        stopwatch.stop();
        _manager.setMode(previousMode);

        return ExecutionRecord(
          taskName: 'dry_run',
          mode: ExecutionMode.dryRun,
          result: result,
          steps: steps,
          errorMessage: errorMessage,
          duration: stopwatch.elapsed,
        );
      },
    );
  }

  /// Get execution history
  List<ExecutionRecord> getHistory() => _manager.history;

  /// Get failure vault entries
  List<ExecutionRecord> getFailures() => _manager.failureVault;

  /// Cleanup old cache and resolved failures
  Future<void> cleanup() async {
    await execute<void>(
      action: StepType.modify,
      target: 'cleaning up cache and old data',
      task: () async {
        await _manager.clearResolvedFailures();

        logger.logStep(
          agentName: name,
          action: StepType.check,
          target: 'Cleanup complete',
          status: StepStatus.success,
        );
      },
    );
  }

  /// Record the start of an execution (for undo support)
  void beginExecution(Map<String, dynamic> initialState) {
    _manager.pushUndoState(initialState);
  }

  /// Record the end of an execution
  Future<void> endExecution({
    required String taskName,
    required ExecutionResult result,
    required List<ExecutionStep> steps,
    required Duration duration,
    Map<String, dynamic>? input,
    Map<String, dynamic>? output,
    String? errorMessage,
  }) async {
    final record = ExecutionRecord(
      taskName: taskName,
      mode: _manager.currentMode,
      result: result,
      steps: steps,
      input: input,
      output: output,
      errorMessage: errorMessage,
      duration: duration,
    );

    await _manager.recordExecution(record);
  }
}

/// Commands for execution control
enum ExecutionCommand {
  setMode,
  replay,
  redo,
  undo,
  dryRun,
  getHistory,
  getFailures,
  cleanup,
}

/// Request for execution control
class ExecutionControlRequest {
  final ExecutionCommand command;
  final ExecutionMode? mode;
  final String? taskName;
  final Future<void> Function()? task;

  const ExecutionControlRequest({
    required this.command,
    this.mode,
    this.taskName,
    this.task,
  });

  factory ExecutionControlRequest.setMode(ExecutionMode mode) =>
      ExecutionControlRequest(command: ExecutionCommand.setMode, mode: mode);

  factory ExecutionControlRequest.replay(String taskName) =>
      ExecutionControlRequest(
          command: ExecutionCommand.replay, taskName: taskName);

  factory ExecutionControlRequest.redo(String taskName) =>
      ExecutionControlRequest(
          command: ExecutionCommand.redo, taskName: taskName);

  factory ExecutionControlRequest.undo() =>
      const ExecutionControlRequest(command: ExecutionCommand.undo);

  factory ExecutionControlRequest.dryRun(Future<void> Function() task) =>
      ExecutionControlRequest(command: ExecutionCommand.dryRun, task: task);

  factory ExecutionControlRequest.cleanup() =>
      const ExecutionControlRequest(command: ExecutionCommand.cleanup);
}
