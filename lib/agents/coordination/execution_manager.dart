import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Execution modes for task running
enum ExecutionMode {
  /// Normal execution with real side effects
  normal,

  /// Simulate execution without side effects
  dryRun,

  /// Re-run a previous successful execution
  replay,

  /// Retry a failed execution
  redo,
}

/// Result of an execution
enum ExecutionResult {
  success,
  failed,
  skipped,
  dryRunComplete,
}

/// A recorded execution for replay/redo
class ExecutionRecord {
  final String id;
  final String taskName;
  final DateTime timestamp;
  final ExecutionMode mode;
  final ExecutionResult result;
  final List<ExecutionStep> steps;
  final Map<String, dynamic>? input;
  final Map<String, dynamic>? output;
  final String? errorMessage;
  final Duration duration;

  ExecutionRecord({
    String? id,
    required this.taskName,
    DateTime? timestamp,
    required this.mode,
    required this.result,
    required this.steps,
    this.input,
    this.output,
    this.errorMessage,
    required this.duration,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskName': taskName,
        'timestamp': timestamp.toIso8601String(),
        'mode': mode.index,
        'result': result.index,
        'steps': steps.map((s) => s.toJson()).toList(),
        'input': input,
        'output': output,
        'errorMessage': errorMessage,
        'durationMs': duration.inMilliseconds,
      };

  factory ExecutionRecord.fromJson(Map<String, dynamic> json) =>
      ExecutionRecord(
        id: json['id'],
        taskName: json['taskName'],
        timestamp: DateTime.parse(json['timestamp']),
        mode: ExecutionMode.values[json['mode']],
        result: ExecutionResult.values[json['result']],
        steps: (json['steps'] as List)
            .map((s) => ExecutionStep.fromJson(s))
            .toList(),
        input: json['input'],
        output: json['output'],
        errorMessage: json['errorMessage'],
        duration: Duration(milliseconds: json['durationMs']),
      );

  /// Check if this can be replayed
  bool get canReplay => result == ExecutionResult.success;

  /// Check if this can be redone
  bool get canRedo => result == ExecutionResult.failed;
}

/// A single step in an execution
class ExecutionStep {
  final String agentName;
  final String action;
  final String target;
  final ExecutionResult result;
  final Map<String, dynamic>? beforeState;
  final Map<String, dynamic>? afterState;
  final Duration duration;

  ExecutionStep({
    required this.agentName,
    required this.action,
    required this.target,
    required this.result,
    this.beforeState,
    this.afterState,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'agentName': agentName,
        'action': action,
        'target': target,
        'result': result.index,
        'beforeState': beforeState,
        'afterState': afterState,
        'durationMs': duration.inMilliseconds,
      };

  factory ExecutionStep.fromJson(Map<String, dynamic> json) => ExecutionStep(
        agentName: json['agentName'],
        action: json['action'],
        target: json['target'],
        result: ExecutionResult.values[json['result']],
        beforeState: json['beforeState'],
        afterState: json['afterState'],
        duration: Duration(milliseconds: json['durationMs']),
      );
}

/// Manager for execution history, replay, and failure vault
class ExecutionManager {
  // Singleton
  static final ExecutionManager _instance = ExecutionManager._internal();
  factory ExecutionManager() => _instance;
  ExecutionManager._internal();

  final List<ExecutionRecord> _history = [];
  final List<ExecutionRecord> _failureVault = [];
  final List<Map<String, dynamic>> _undoStack = [];

  String? _storagePath;
  bool _initialized = false;
  ExecutionMode _currentMode = ExecutionMode.normal;

  /// Current execution mode
  ExecutionMode get currentMode => _currentMode;

  /// Set execution mode
  void setMode(ExecutionMode mode) => _currentMode = mode;

  /// Initialize the manager
  Future<void> initialize() async {
    if (_initialized) return;

    final docsDir = await getApplicationDocumentsDirectory();
    _storagePath = p.join(docsDir.path, 'execution');

    final dir = Directory(_storagePath!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await _loadHistory();
    await _loadFailureVault();
    _initialized = true;
  }

  /// Get execution history
  List<ExecutionRecord> get history => List.unmodifiable(_history);

  /// Get failure vault entries
  List<ExecutionRecord> get failureVault => List.unmodifiable(_failureVault);

  /// Record a new execution
  Future<void> recordExecution(ExecutionRecord record) async {
    _history.add(record);
    await _saveHistory();

    if (record.result == ExecutionResult.failed) {
      // Add to failure vault (like git commit for failures)
      _failureVault.add(record);
      await _saveFailureVault();
    } else if (record.result == ExecutionResult.success) {
      // Auto-cleanup on success
      await _cleanupOnSuccess(record);
    }
  }

  /// Prepare for undo by saving current state
  void pushUndoState(Map<String, dynamic> state) {
    _undoStack.add(state);
    // Keep only last 10 undo states
    if (_undoStack.length > 10) {
      _undoStack.removeAt(0);
    }
  }

  /// Pop undo state
  Map<String, dynamic>? popUndoState() {
    if (_undoStack.isEmpty) return null;
    return _undoStack.removeLast();
  }

  /// Check if undo is available
  bool get canUndo => _undoStack.isNotEmpty;

  /// Find a record to replay
  ExecutionRecord? findForReplay(String taskName) {
    try {
      return _history.lastWhere(
        (r) => r.taskName == taskName && r.canReplay,
      );
    } catch (_) {
      return null;
    }
  }

  /// Find a record to redo
  ExecutionRecord? findForRedo(String taskName) {
    try {
      return _failureVault.lastWhere(
        (r) => r.taskName == taskName && r.canRedo,
      );
    } catch (_) {
      return null;
    }
  }

  /// Clear failure vault entry after successful redo
  Future<void> resolveFailure(String recordId) async {
    _failureVault.removeWhere((r) => r.id == recordId);
    await _saveFailureVault();
  }

  /// Clean up cache and temp files on success
  Future<void> _cleanupOnSuccess(ExecutionRecord record) async {
    final docsDir = await getApplicationDocumentsDirectory();

    // Clean cache zone
    final cacheDir = Directory(p.join(docsDir.path, 'storage', 'cache'));
    if (await cacheDir.exists()) {
      await for (final entity in cacheDir.list()) {
        // Delete files older than 1 hour
        if (entity is File) {
          final stat = await entity.stat();
          if (DateTime.now().difference(stat.modified) >
              const Duration(hours: 1)) {
            await entity.delete();
          }
        }
      }
    }

    // Clean tasks zone (temporary files)
    final tasksDir = Directory(p.join(docsDir.path, 'storage', 'tasks'));
    if (await tasksDir.exists()) {
      await for (final entity in tasksDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (DateTime.now().difference(stat.modified) >
              const Duration(hours: 24)) {
            await entity.delete();
          }
        }
      }
    }
  }

  Future<void> _loadHistory() async {
    final file = File(p.join(_storagePath!, 'history.json'));
    if (!await file.exists()) return;

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as List;
      _history.clear();
      _history.addAll(data.map((j) => ExecutionRecord.fromJson(j)));
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    final file = File(p.join(_storagePath!, 'history.json'));
    // Keep only last 100 records
    final toSave = _history.length > 100
        ? _history.sublist(_history.length - 100)
        : _history;
    await file
        .writeAsString(jsonEncode(toSave.map((r) => r.toJson()).toList()));
  }

  Future<void> _loadFailureVault() async {
    final file = File(p.join(_storagePath!, 'failure_vault.json'));
    if (!await file.exists()) return;

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as List;
      _failureVault.clear();
      _failureVault.addAll(data.map((j) => ExecutionRecord.fromJson(j)));
    } catch (_) {}
  }

  Future<void> _saveFailureVault() async {
    final file = File(p.join(_storagePath!, 'failure_vault.json'));
    await file.writeAsString(
        jsonEncode(_failureVault.map((r) => r.toJson()).toList()));
  }

  /// Clear all history
  Future<void> clearHistory() async {
    _history.clear();
    await _saveHistory();
  }

  /// Clear resolved failures from vault
  Future<void> clearResolvedFailures() async {
    // Keep only recent failures (last 7 days)
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _failureVault.removeWhere((r) => r.timestamp.isBefore(cutoff));
    await _saveFailureVault();
  }
}
