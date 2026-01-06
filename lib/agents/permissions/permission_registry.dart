import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'permission_types.dart';
import 'permission_entry.dart';

/// Central authority for all storage permissions.
///
/// This singleton manages:
/// - Loading/saving permissions from encrypted storage
/// - Access checks (canRead, canWrite, canTrain, etc.)
/// - Permission grants and revocations
/// - Version history tracking
class PermissionRegistry {
  // Singleton pattern
  static final PermissionRegistry _instance = PermissionRegistry._internal();
  factory PermissionRegistry() => _instance;
  PermissionRegistry._internal();

  /// All active permissions
  final List<PermissionEntry> _permissions = [];

  /// Historical versions (for audit trail)
  final List<PermissionEntry> _versionHistory = [];

  /// File path for persistence
  String? _storagePath;

  /// Whether the registry has been initialized
  bool _initialized = false;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize the registry and load permissions from disk
  Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _storagePath = p.join(dir.path, 'permissions', 'registry.json');

    await _ensureDirectoryExists();
    await load();
    _initialized = true;
  }

  Future<void> _ensureDirectoryExists() async {
    final dir = Directory(p.dirname(_storagePath!));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  // ============================================================
  // ACCESS CHECKS
  // ============================================================

  /// Check if an agent can read from a path
  bool canRead(String agent, String path) {
    return _checkPermission(
        agent, GranteeType.agent, path, PermissionType.read);
  }

  /// Check if an agent can write to a path
  bool canWrite(String agent, String path) {
    return _checkPermission(
        agent, GranteeType.agent, path, PermissionType.write);
  }

  /// Check if an agent can delete from a path
  bool canDelete(String agent, String path) {
    return _checkPermission(
        agent, GranteeType.agent, path, PermissionType.delete);
  }

  /// Check if a model can train on data at a path
  bool canTrain(String model, String path) {
    return _checkPermission(
        model, GranteeType.model, path, PermissionType.train);
  }

  /// Check if an agent can execute at a path
  bool canExecute(String agent, String path) {
    return _checkPermission(
        agent, GranteeType.agent, path, PermissionType.execute);
  }

  /// Core permission check with hierarchical inheritance
  bool _checkPermission(
    String grantee,
    GranteeType granteeType,
    String path,
    PermissionType type,
  ) {
    // Normalize path
    final normalizedPath = _normalizePath(path);

    for (final perm in _permissions) {
      // Must match grantee and type
      if (perm.grantee != grantee) continue;
      if (perm.granteeType != granteeType) continue;

      // Must not be expired
      if (perm.isExpired) continue;

      // Must grant this permission type
      if (!perm.grants(type)) continue;

      // Must match path (exact or recursive)
      if (perm.matchesPath(normalizedPath)) {
        return true;
      }
    }

    // DENY by default - no implicit access
    return false;
  }

  String _normalizePath(String path) {
    // Remove trailing slashes and normalize
    return path.replaceAll('\\', '/').replaceAll(RegExp(r'/+$'), '');
  }

  // ============================================================
  // PERMISSION MANAGEMENT
  // ============================================================

  /// Grant a new permission
  Future<void> grant(PermissionEntry entry) async {
    _permissions.add(entry);
    await save();
  }

  /// Revoke a permission by ID
  Future<void> revoke(String permissionId) async {
    final index = _permissions.indexWhere((p) => p.id == permissionId);
    if (index != -1) {
      final revoked = _permissions.removeAt(index);
      _versionHistory.add(revoked); // Keep history
      await save();
    }
  }

  /// Update a permission (creates new version)
  Future<void> update(
    String permissionId, {
    Set<PermissionType>? permissions,
    PermissionScope? scope,
    DateTime? expiresAt,
    required String updatedBy,
  }) async {
    final index = _permissions.indexWhere((p) => p.id == permissionId);
    if (index == -1) return;

    final old = _permissions[index];
    _versionHistory.add(old); // Archive old version

    final updated = old.copyWithNewVersion(
      permissions: permissions,
      scope: scope,
      expiresAt: expiresAt,
      updatedBy: updatedBy,
    );

    _permissions[index] = updated;
    await save();
  }

  // ============================================================
  // QUERIES
  // ============================================================

  /// Get all permissions for a specific grantee
  List<PermissionEntry> getPermissionsFor(String grantee) {
    return _permissions.where((p) => p.grantee == grantee).toList();
  }

  /// Get all permissions at a specific path
  List<PermissionEntry> getPermissionsAt(String path) {
    final normalized = _normalizePath(path);
    return _permissions.where((p) => p.matchesPath(normalized)).toList();
  }

  /// Find a specific permission by ID
  PermissionEntry? findPermission(String id) {
    try {
      return _permissions.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get version history for a permission chain
  List<PermissionEntry> getVersionHistory(String permissionId) {
    final history = <PermissionEntry>[];
    String? currentId = permissionId;

    while (currentId != null) {
      // Check current permissions
      final current = findPermission(currentId);
      if (current != null) {
        history.add(current);
        currentId = current.previousVersionId;
        continue;
      }

      // Check history
      try {
        final archived = _versionHistory.firstWhere((p) => p.id == currentId);
        history.add(archived);
        currentId = archived.previousVersionId;
      } catch (_) {
        break;
      }
    }

    return history.reversed.toList(); // Oldest first
  }

  /// Get all active permissions
  List<PermissionEntry> get allPermissions => List.unmodifiable(_permissions);

  // ============================================================
  // PERSISTENCE
  // ============================================================

  /// Load permissions from disk
  Future<void> load() async {
    if (_storagePath == null) return;

    final file = File(_storagePath!);
    if (!await file.exists()) return;

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      _permissions.clear();
      _versionHistory.clear();

      if (data['permissions'] != null) {
        for (final json in data['permissions']) {
          _permissions.add(PermissionEntry.fromJson(json));
        }
      }

      if (data['history'] != null) {
        for (final json in data['history']) {
          _versionHistory.add(PermissionEntry.fromJson(json));
        }
      }
    } catch (e) {
      // If file is corrupted, start fresh
      _permissions.clear();
      _versionHistory.clear();
    }
  }

  /// Save permissions to disk
  Future<void> save() async {
    if (_storagePath == null) return;

    final data = {
      'version': 1,
      'savedAt': DateTime.now().toIso8601String(),
      'permissions': _permissions.map((p) => p.toJson()).toList(),
      'history': _versionHistory.map((p) => p.toJson()).toList(),
    };

    final file = File(_storagePath!);
    await file.writeAsString(jsonEncode(data));
  }

  /// Clear all permissions (for testing)
  Future<void> clear() async {
    _permissions.clear();
    _versionHistory.clear();
    await save();
  }
}
