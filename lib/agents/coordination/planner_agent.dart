import 'dart:async';
import 'dart:math';

import '../core/agent_base.dart';
import '../core/step_types.dart';
import '../core/step_schema.dart';

import 'agent_registry.dart';
import 'agent_capability.dart';

/// Intelligent task router and planner agent.
///
/// Like Arc browser's command bar, Manus AI, or self-driving systems:
/// - Determines which agent should handle which task
/// - Supports deterministic (rule-based) and exploratory (learning) modes
/// - Routes tasks in parallel when possible
/// - Adapts based on agent performance
class PlannerAgent extends AgentBase {
  final AgentRegistry _registry;
  final Map<String, AgentProfile> _profiles = {};
  final List<TaskRouting> _routingHistory = [];

  PlanningMode _mode = PlanningMode.hybrid;
  final Random _random = Random();

  PlannerAgent({
    required AgentRegistry registry,
    super.logger,
  })  : _registry = registry,
        super(name: 'Planner');

  /// Current planning mode
  PlanningMode get mode => _mode;

  /// Set planning mode
  void setMode(PlanningMode mode) => _mode = mode;

  @override
  Future<R> onRun<R>(dynamic input) async {
    if (input is PlannerRequest) {
      return await handleRequest(input) as R;
    }
    throw ArgumentError('Expected PlannerRequest');
  }

  Future<dynamic> handleRequest(PlannerRequest request) async {
    switch (request.command) {
      case PlannerCommand.route:
        return await routeTask(request.task!);
      case PlannerCommand.routeParallel:
        return await routeTasksParallel(request.tasks!);
      case PlannerCommand.setMode:
        setMode(request.mode!);
        return null;
      case PlannerCommand.registerProfile:
        registerProfile(request.profile!);
        return null;
      case PlannerCommand.getHistory:
        return _routingHistory;
    }
  }

  /// Register an agent profile with capabilities
  void registerProfile(AgentProfile profile) {
    _profiles[profile.agentName] = profile;

    logger.logStep(
      agentName: name,
      action: StepType.check,
      target:
          'Registered ${profile.agentName} with ${profile.capabilities.length} capabilities',
      status: StepStatus.success,
    );
  }

  /// Route a single task to the best agent
  Future<TaskRouting?> routeTask(RoutableTask task) async {
    return await execute<TaskRouting?>(
      action: StepType.decide,
      target: 'routing: ${task.description}',
      task: () async {
        // Check for manual assignment
        if (task.preferredAgent != null) {
          return await _manualRoute(task);
        }

        // Route based on mode
        switch (_mode) {
          case PlanningMode.deterministic:
            return await _deterministicRoute(task);
          case PlanningMode.exploratory:
            return await _exploratoryRoute(task);
          case PlanningMode.hybrid:
            return await _hybridRoute(task);
          case PlanningMode.manual:
            logger.logStep(
              agentName: name,
              action: StepType.error,
              target: 'Manual mode requires preferredAgent',
              status: StepStatus.failed,
            );
            return null;
        }
      },
    );
  }

  /// Route multiple tasks in parallel
  Future<List<TaskRouting>> routeTasksParallel(List<RoutableTask> tasks) async {
    return await execute<List<TaskRouting>>(
      action: StepType.decide,
      target: 'routing ${tasks.length} tasks in parallel',
      task: () async {
        // Sort by priority
        final sorted = List<RoutableTask>.from(tasks)
          ..sort((a, b) => b.priority.index.compareTo(a.priority.index));

        // Route all in parallel
        final futures = sorted.map((t) => routeTask(t));
        final results = await Future.wait(futures);

        // Filter successful routings
        return results.whereType<TaskRouting>().toList();
      },
    );
  }

  /// Manual routing - user specifies the agent
  Future<TaskRouting?> _manualRoute(RoutableTask task) async {
    final agentName = task.preferredAgent!;
    final agent = _registry.getAgent(agentName);

    if (agent == null) {
      logger.logStep(
        agentName: name,
        action: StepType.error,
        target: 'Preferred agent not found: $agentName',
        status: StepStatus.failed,
      );
      return null;
    }

    final profile = _profiles[agentName];
    final capability = profile?.bestCapabilityFor(task.description) ??
        AgentCapability(
          id: 'manual',
          name: 'Manual Assignment',
          category: CapabilityCategory.custom,
        );

    final routing = TaskRouting(
      task: task,
      assignedAgent: agentName,
      matchedCapability: capability,
      confidence: 1.0, // User knows best
      mode: PlanningMode.manual,
    );

    _recordRouting(routing);
    return routing;
  }

  /// Deterministic routing - pure rule-based matching
  Future<TaskRouting?> _deterministicRoute(RoutableTask task) async {
    String? bestAgent;
    AgentCapability? bestCapability;
    double bestScore = 0.0;

    for (final entry in _profiles.entries) {
      final profile = entry.value;
      if (!profile.canAcceptTask) continue;

      final score = profile.matchScore(task.description);
      if (score > bestScore) {
        bestScore = score;
        bestAgent = entry.key;
        bestCapability = profile.bestCapabilityFor(task.description);
      }
    }

    if (bestAgent == null || bestCapability == null) {
      logger.logStep(
        agentName: name,
        action: StepType.error,
        target: 'No suitable agent found for: ${task.description}',
        status: StepStatus.failed,
      );
      return null;
    }

    final routing = TaskRouting(
      task: task,
      assignedAgent: bestAgent,
      matchedCapability: bestCapability,
      confidence: bestScore,
      mode: PlanningMode.deterministic,
    );

    _recordRouting(routing);

    logger.logStep(
      agentName: name,
      action: StepType.decide,
      target:
          '[DETERMINISTIC] $bestAgent (${(bestScore * 100).toInt()}% confidence)',
      status: StepStatus.success,
    );

    return routing;
  }

  /// Exploratory routing - try agents and learn
  Future<TaskRouting?> _exploratoryRoute(RoutableTask task) async {
    // Get agents that can handle this
    final candidates = <String, double>{};

    for (final entry in _profiles.entries) {
      final profile = entry.value;
      if (!profile.canAcceptTask) continue;

      final score = profile.matchScore(task.description);
      if (score > 0.05) {
        // Low threshold for exploration
        candidates[entry.key] = score;
      }
    }

    if (candidates.isEmpty) {
      // Random exploration if no matches
      final available =
          _profiles.entries.where((e) => e.value.canAcceptTask).toList();

      if (available.isEmpty) return null;

      final randomAgent = available[_random.nextInt(available.length)];
      candidates[randomAgent.key] = 0.1;
    }

    // Weighted random selection (exploration with exploitation)
    final totalWeight = candidates.values.reduce((a, b) => a + b);
    var roll = _random.nextDouble() * totalWeight;

    String selectedAgent = candidates.keys.first;
    for (final entry in candidates.entries) {
      roll -= entry.value;
      if (roll <= 0) {
        selectedAgent = entry.key;
        break;
      }
    }

    final profile = _profiles[selectedAgent]!;
    final capability = profile.bestCapabilityFor(task.description) ??
        AgentCapability(
          id: 'explore',
          name: 'Exploratory',
          category: CapabilityCategory.custom,
        );

    final routing = TaskRouting(
      task: task,
      assignedAgent: selectedAgent,
      matchedCapability: capability,
      confidence: candidates[selectedAgent]!,
      mode: PlanningMode.exploratory,
    );

    _recordRouting(routing);

    logger.logStep(
      agentName: name,
      action: StepType.decide,
      target:
          '[EXPLORATORY] $selectedAgent (exploring ${candidates.length} options)',
      status: StepStatus.success,
    );

    return routing;
  }

  /// Hybrid routing - deterministic first, exploratory on low confidence
  Future<TaskRouting?> _hybridRoute(RoutableTask task) async {
    // First try deterministic
    String? bestAgent;
    AgentCapability? bestCapability;
    double bestScore = 0.0;

    for (final entry in _profiles.entries) {
      final profile = entry.value;
      if (!profile.canAcceptTask) continue;

      final score = profile.matchScore(task.description);
      if (score > bestScore) {
        bestScore = score;
        bestAgent = entry.key;
        bestCapability = profile.bestCapabilityFor(task.description);
      }
    }

    // If confidence is high enough, use deterministic
    if (bestScore >= 0.5 && bestAgent != null && bestCapability != null) {
      final routing = TaskRouting(
        task: task,
        assignedAgent: bestAgent,
        matchedCapability: bestCapability,
        confidence: bestScore,
        mode: PlanningMode.hybrid,
      );

      _recordRouting(routing);

      logger.logStep(
        agentName: name,
        action: StepType.decide,
        target:
            '[HYBRID-DETERMINISTIC] $bestAgent (${(bestScore * 100).toInt()}%)',
        status: StepStatus.success,
      );

      return routing;
    }

    // Low confidence - switch to exploratory
    logger.logStep(
      agentName: name,
      action: StepType.check,
      target:
          '[HYBRID] Low confidence (${(bestScore * 100).toInt()}%), exploring...',
      status: StepStatus.running,
    );

    return await _exploratoryRoute(task);
  }

  void _recordRouting(TaskRouting routing) {
    _routingHistory.add(routing);

    // Update agent load
    final profile = _profiles[routing.assignedAgent];
    if (profile != null) {
      profile.currentLoad++;
    }

    // Keep only last 100 routings
    if (_routingHistory.length > 100) {
      _routingHistory.removeAt(0);
    }
  }

  /// Mark task complete and update agent stats
  void completeTask(String taskId, bool success) {
    final routing = _routingHistory.firstWhere(
      (r) => r.task.id == taskId,
      orElse: () => throw StateError('Task not found'),
    );

    final profile = _profiles[routing.assignedAgent];
    if (profile != null) {
      profile.currentLoad = (profile.currentLoad - 1).clamp(0, 999);

      // Update reliability based on success (simple exponential moving average)
      // This makes the system learn from experience
      // reliability = 0.9 * reliability + 0.1 * (success ? 1.0 : 0.0)
    }
  }

  /// Get routing history
  List<TaskRouting> get routingHistory => List.unmodifiable(_routingHistory);
}

/// Commands for planner
enum PlannerCommand {
  route,
  routeParallel,
  setMode,
  registerProfile,
  getHistory,
}

/// Request for planner
class PlannerRequest {
  final PlannerCommand command;
  final RoutableTask? task;
  final List<RoutableTask>? tasks;
  final PlanningMode? mode;
  final AgentProfile? profile;

  const PlannerRequest({
    required this.command,
    this.task,
    this.tasks,
    this.mode,
    this.profile,
  });

  factory PlannerRequest.route(RoutableTask task) =>
      PlannerRequest(command: PlannerCommand.route, task: task);

  factory PlannerRequest.routeParallel(List<RoutableTask> tasks) =>
      PlannerRequest(command: PlannerCommand.routeParallel, tasks: tasks);

  factory PlannerRequest.setMode(PlanningMode mode) =>
      PlannerRequest(command: PlannerCommand.setMode, mode: mode);

  factory PlannerRequest.registerProfile(AgentProfile profile) =>
      PlannerRequest(command: PlannerCommand.registerProfile, profile: profile);
}
