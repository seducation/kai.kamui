import 'package:flutter/material.dart';
import '../rules/rule_engine.dart';
import '../rules/rule_definitions.dart';
import '../coordination/task_queue.dart';

/// Screen for managing Rules and viewing Priority Queue state 🧠⚡
class RulePriorityScreen extends StatefulWidget {
  const RulePriorityScreen({super.key});

  @override
  State<RulePriorityScreen> createState() => _RulePriorityScreenState();
}

class _RulePriorityScreenState extends State<RulePriorityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RuleEngine _ruleEngine = RuleEngine();
  final TaskQueue _taskQueue = taskQueue;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rules & Priority Engine'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.gavel), text: 'Rule Engine'),
            Tab(icon: Icon(Icons.low_priority), text: 'Priority Queue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRuleEngineView(),
          _buildPriorityQueueView(),
        ],
      ),
    );
  }

  Widget _buildRuleEngineView() {
    final rules = _ruleEngine.rules;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rules.length,
      itemBuilder: (context, index) {
        final rule = rules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            leading: Icon(
              _getActionIcon(rule.action),
              color: _getActionColor(rule.action),
            ),
            title: Text(
              rule.id,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(rule.explanation),
            trailing: Chip(
              label: Text('P${rule.priority}'),
              backgroundColor: Colors.blue.withOpacity(0.1),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Type', rule.type.name.toUpperCase()),
                    _infoRow('Scope', rule.scope.name.toUpperCase()),
                    _infoRow('Condition', rule.condition),
                    _infoRow('Immutable', rule.immutable ? 'YES' : 'NO'),
                    if (rule.targetId != null)
                      _infoRow('Target', rule.targetId!),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriorityQueueView() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final running = _taskQueue.runningTasks;
        final buckets = _taskQueue.priorityBuckets;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Currently Running',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (running.isEmpty)
              const Center(child: Text('No active tasks'))
            else
              ...running.map((t) => _buildTaskTile(t)),
            const Divider(height: 32),
            const Text(
              'Priority Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...buckets.entries.map((entry) {
              final levelName = PriorityLevel.getName(entry.key);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text('$levelName (P${entry.key})',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('${entry.value.length} pending'),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    value: entry.value.isEmpty ? 0 : 0.7, // Visual placeholder
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation(_getPriorityColor(entry.key)),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildTaskTile(QueuedTask task) {
    return Card(
      elevation: 0,
      color: Colors.blue.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const CircularProgressIndicator(strokeWidth: 2),
        title: Text(task.id, style: const TextStyle(fontSize: 14)),
        subtitle: Text('Agent: ${task.agent.name}',
            style: const TextStyle(fontSize: 12)),
        trailing: Text(PriorityLevel.getName(task.priority)),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        ],
      ),
    );
  }

  IconData _getActionIcon(RuleAction action) {
    switch (action) {
      case RuleAction.allow:
        return Icons.check_circle;
      case RuleAction.deny:
        return Icons.block;
      case RuleAction.modify:
        return Icons.edit_note;
      case RuleAction.escalate:
        return Icons.security;
      case RuleAction.defer:
        return Icons.timer;
    }
  }

  Color _getActionColor(RuleAction action) {
    switch (action) {
      case RuleAction.allow:
        return Colors.green;
      case RuleAction.deny:
        return Colors.red;
      case RuleAction.modify:
        return Colors.blue;
      case RuleAction.escalate:
        return Colors.orange;
      case RuleAction.defer:
        return Colors.purple;
    }
  }

  Color _getPriorityColor(int priority) {
    if (priority >= PriorityLevel.reflex) return Colors.red;
    if (priority >= PriorityLevel.emergency) return Colors.orange;
    if (priority >= PriorityLevel.high) return Colors.blue;
    if (priority >= PriorityLevel.normal) return Colors.green;
    return Colors.grey;
  }
}
