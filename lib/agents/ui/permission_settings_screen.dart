import 'package:flutter/material.dart';
import '../permissions/permission_types.dart';
import '../permissions/permission_entry.dart';
import '../permissions/permission_registry.dart';
import '../permissions/access_gate.dart';

/// Screen for managing storage permissions.
///
/// This is the ONLY interface for granting/revoking agent permissions.
/// Agents cannot access this functionality directly.
class PermissionSettingsScreen extends StatefulWidget {
  const PermissionSettingsScreen({super.key});

  @override
  State<PermissionSettingsScreen> createState() =>
      _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends State<PermissionSettingsScreen> {
  final PermissionRegistry _registry = PermissionRegistry();
  final AccessGate _gate = AccessGate();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _gate.initialize();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 Permission Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddPermissionDialog(context),
            tooltip: 'Add Permission',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showAuditLog(context),
            tooltip: 'Audit Log',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPermissionList(),
    );
  }

  Widget _buildPermissionList() {
    final permissions = _registry.allPermissions;

    if (permissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No permissions configured',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'All agents are denied access by default',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddPermissionDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add First Permission'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: permissions.length,
      itemBuilder: (context, index) {
        final perm = permissions[index];
        return _PermissionCard(
          permission: perm,
          onEdit: () => _showEditPermissionDialog(context, perm),
          onRevoke: () => _revokePermission(perm.id),
        );
      },
    );
  }

  Future<void> _showAddPermissionDialog(BuildContext context) async {
    final result = await showDialog<PermissionEntry>(
      context: context,
      builder: (context) => const _PermissionDialog(),
    );

    if (result != null) {
      await _registry.grant(result);
      setState(() {});
    }
  }

  Future<void> _showEditPermissionDialog(
      BuildContext context, PermissionEntry perm) async {
    final result = await showDialog<PermissionEntry>(
      context: context,
      builder: (context) => _PermissionDialog(existing: perm),
    );

    if (result != null) {
      await _registry.update(
        perm.id,
        permissions: result.permissions,
        scope: result.scope,
        expiresAt: result.expiresAt,
        updatedBy: 'Admin',
      );
      setState(() {});
    }
  }

  Future<void> _revokePermission(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Permission?'),
        content:
            const Text('This will immediately deny access for this agent.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _registry.revoke(id);
      setState(() {});
    }
  }

  void _showAuditLog(BuildContext context) {
    final entries = _gate.auditLog.entries;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.history),
                  const SizedBox(width: 8),
                  Text(
                    'Audit Log (${entries.length} entries)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('No access attempts logged'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry =
                            entries[entries.length - 1 - index]; // Newest first
                        return ListTile(
                          leading: Icon(
                            entry.result == AccessResult.allowed
                                ? Icons.check_circle
                                : Icons.block,
                            color: entry.result == AccessResult.allowed
                                ? Colors.green
                                : Colors.red,
                          ),
                          title:
                              Text('${entry.requester}: ${entry.action.name}'),
                          subtitle: Text(entry.resource),
                          trailing: Text(
                            '${entry.timestamp.hour}:${entry.timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final PermissionEntry permission;
  final VoidCallback onEdit;
  final VoidCallback onRevoke;

  const _PermissionCard({
    required this.permission,
    required this.onEdit,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = permission.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  permission.granteeType == GranteeType.agent
                      ? Icons.smart_toy
                      : Icons.psychology,
                  color: isExpired ? Colors.grey : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    permission.grantee,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isExpired ? Colors.grey : null,
                      decoration: isExpired ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (isExpired)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('EXPIRED',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.folder, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  permission.resourcePath,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: permission.scope == PermissionScope.recursive
                        ? Colors.orange[100]
                        : Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    permission.scope == PermissionScope.recursive
                        ? 'RECURSIVE'
                        : 'EXACT',
                    style: TextStyle(
                      fontSize: 10,
                      color: permission.scope == PermissionScope.recursive
                          ? Colors.orange[800]
                          : Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: permission.permissions
                  .map((p) => Chip(
                        avatar: Text(p.icon),
                        label: Text(p.displayName),
                        visualDensity: VisualDensity.compact,
                      ))
                  .toList(),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                TextButton.icon(
                  onPressed: onRevoke,
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label:
                      const Text('Revoke', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionDialog extends StatefulWidget {
  final PermissionEntry? existing;

  const _PermissionDialog({this.existing});

  @override
  State<_PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<_PermissionDialog> {
  final _granteeController = TextEditingController();
  final _pathController = TextEditingController();
  GranteeType _granteeType = GranteeType.agent;
  PermissionScope _scope = PermissionScope.exact;
  final Set<PermissionType> _permissions = {};

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _granteeController.text = widget.existing!.grantee;
      _pathController.text = widget.existing!.resourcePath;
      _granteeType = widget.existing!.granteeType;
      _scope = widget.existing!.scope;
      _permissions.addAll(widget.existing!.permissions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.existing == null ? 'Add Permission' : 'Edit Permission'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grantee Type
            SegmentedButton<GranteeType>(
              segments: const [
                ButtonSegment(
                    value: GranteeType.agent,
                    label: Text('Agent'),
                    icon: Icon(Icons.smart_toy)),
                ButtonSegment(
                    value: GranteeType.model,
                    label: Text('Model'),
                    icon: Icon(Icons.psychology)),
              ],
              selected: {_granteeType},
              onSelectionChanged: (s) => setState(() => _granteeType = s.first),
            ),
            const SizedBox(height: 16),

            // Grantee Name
            TextField(
              controller: _granteeController,
              decoration: InputDecoration(
                labelText: _granteeType == GranteeType.agent
                    ? 'Agent Name'
                    : 'Model Name',
                hintText: _granteeType == GranteeType.agent
                    ? 'e.g., CodeWriter'
                    : 'e.g., GPT-4',
                border: const OutlineInputBorder(),
              ),
              enabled: widget.existing == null,
            ),
            const SizedBox(height: 16),

            // Resource Path
            TextField(
              controller: _pathController,
              decoration: const InputDecoration(
                labelText: 'Resource Path',
                hintText: 'e.g., vault/research',
                border: OutlineInputBorder(),
              ),
              enabled: widget.existing == null,
            ),
            const SizedBox(height: 16),

            // Scope
            SegmentedButton<PermissionScope>(
              segments: const [
                ButtonSegment(
                    value: PermissionScope.exact, label: Text('Exact')),
                ButtonSegment(
                    value: PermissionScope.recursive, label: Text('Recursive')),
              ],
              selected: {_scope},
              onSelectionChanged: (s) => setState(() => _scope = s.first),
            ),
            const SizedBox(height: 16),

            // Permissions
            const Text('Permissions:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: PermissionType.values
                  .map((type) => FilterChip(
                        avatar: Text(type.icon),
                        label: Text(type.displayName),
                        selected: _permissions.contains(type),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _permissions.add(type);
                            } else {
                              _permissions.remove(type);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _permissions.isEmpty ||
                  _granteeController.text.isEmpty ||
                  _pathController.text.isEmpty
              ? null
              : () {
                  final entry = PermissionEntry(
                    resourcePath: _pathController.text,
                    scope: _scope,
                    grantee: _granteeController.text,
                    granteeType: _granteeType,
                    permissions: _permissions,
                    createdBy: 'Admin',
                  );
                  Navigator.pop(context, entry);
                },
          child: Text(widget.existing == null ? 'Grant' : 'Update'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _granteeController.dispose();
    _pathController.dispose();
    super.dispose();
  }
}
