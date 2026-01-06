import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../core/agent_base.dart';
import '../core/step_schema.dart';
import '../core/step_types.dart';
import '../permissions/access_gate.dart';
import '../permissions/permission_types.dart';

/// Agent for persistent storage operations with permission enforcement.
///
/// All operations are gated by the AccessGate - no implicit access allowed.
class StorageAgent extends AgentBase {
  /// In-memory cache for performance
  final Map<String, dynamic> _cache = {};

  /// Root directory for the vault
  Directory? _vaultDir;

  /// Access gate for permission enforcement
  final AccessGate _gate = AccessGate();

  StorageAgent({
    super.logger,
  }) : super(name: 'Storage');

  Future<void> _initVault() async {
    if (_vaultDir != null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    _vaultDir = Directory(p.join(docsDir.path, 'vault'));

    if (!await _vaultDir!.exists()) {
      await _vaultDir!.create(recursive: true);
      logStatus(StepType.check, 'created vault at ${_vaultDir!.path}',
          StepStatus.success);
    }

    // Initialize the access gate
    await _gate.initialize();
  }

  File _getFile(String key) {
    // Sanitize key to prevent path traversal
    final safeKey = key.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    // Using simple extension inference or default to .md
    final ext = safeKey.contains('.') ? '' : '.md';
    return File(p.join(_vaultDir!.path, '$safeKey$ext'));
  }

  /// Get the resource path for permission checking
  String _getResourcePath(String key) {
    return 'vault/$key';
  }

  @override
  Future<R> onRun<R>(dynamic input) async {
    await _initVault();
    if (input is StorageRequest) {
      return await handleRequest(input) as R;
    }
    throw ArgumentError('Expected StorageRequest');
  }

  /// Handle a storage request
  Future<dynamic> handleRequest(StorageRequest request) async {
    switch (request.operation) {
      case StorageOperation.save:
        return await save(
          request.key,
          request.value,
          requester: request.requester ?? 'Unknown',
        );
      case StorageOperation.load:
        return await load(
          request.key,
          requester: request.requester ?? 'Unknown',
        );
      case StorageOperation.delete:
        return await remove(
          request.key,
          requester: request.requester ?? 'Unknown',
        );
      case StorageOperation.exists:
        return await exists(
          request.key,
          requester: request.requester ?? 'Unknown',
        );
      case StorageOperation.list:
        return await listKeys(
          request.prefix,
          requester: request.requester ?? 'Unknown',
        );
    }
  }

  /// Save a value (requires write permission)
  Future<void> save(String key, dynamic value,
      {required String requester}) async {
    await _initVault();
    final resourcePath = _getResourcePath(key);

    // PERMISSION CHECK - Must have write access
    final allowed = await _gate.canWrite(requester, resourcePath);
    if (!allowed) {
      throw PermissionDeniedException(
        requester: requester,
        resource: resourcePath,
        action: PermissionType.write,
      );
    }

    // Step 1: Validate key
    await execute<void>(
      action: StepType.check,
      target: 'validating key: $key',
      task: () async {
        if (key.isEmpty) throw ArgumentError('Key cannot be empty');
      },
    );

    // Step 2: Write to disk
    await execute<void>(
      action: StepType.store,
      target: key,
      task: () async {
        final file = _getFile(key);

        String content;
        if (value is String) {
          content = value;
        } else {
          content = value.toString();
        }

        await file.writeAsString(content);

        // Update in-memory cache
        _cache[key] = value;
      },
      metadata: {
        'path': _getFile(key).path,
        'type': value.runtimeType.toString(),
        'requester': requester,
      },
    );
  }

  /// Load a value (requires read permission)
  Future<dynamic> load(String key, {required String requester}) async {
    await _initVault();
    final resourcePath = _getResourcePath(key);

    // PERMISSION CHECK - Must have read access
    final allowed = await _gate.canRead(requester, resourcePath);
    if (!allowed) {
      throw PermissionDeniedException(
        requester: requester,
        resource: resourcePath,
        action: PermissionType.read,
      );
    }

    // Step 1: Check cache
    if (_cache.containsKey(key)) {
      logStatus(StepType.fetch, 'loaded from cache: $key', StepStatus.success);
      return _cache[key];
    }

    // Step 2: Read from disk
    return await execute<dynamic>(
      action: StepType.fetch,
      target: key,
      task: () async {
        final file = _getFile(key);
        if (!await file.exists()) return null;

        final content = await file.readAsString();
        _cache[key] = content; // Cache it
        return content;
      },
      metadata: {'requester': requester},
    );
  }

  /// Remove a value (requires delete permission)
  Future<void> remove(String key, {required String requester}) async {
    await _initVault();
    final resourcePath = _getResourcePath(key);

    // PERMISSION CHECK - Must have delete access
    final result = await _gate.requestAccess(
      requester: requester,
      requesterType: GranteeType.agent,
      resourcePath: resourcePath,
      action: PermissionType.delete,
    );

    if (result != AccessResult.allowed) {
      throw PermissionDeniedException(
        requester: requester,
        resource: resourcePath,
        action: PermissionType.delete,
      );
    }

    await execute<void>(
      action: StepType.modify,
      target: 'removing: $key',
      task: () async {
        final file = _getFile(key);
        if (await file.exists()) {
          await file.delete();
        }
        _cache.remove(key);
      },
      metadata: {'requester': requester},
    );
  }

  /// Check if key exists (requires read permission)
  Future<bool> exists(String key, {required String requester}) async {
    await _initVault();
    final resourcePath = _getResourcePath(key);

    // PERMISSION CHECK - Need at least read access to check existence
    final allowed = await _gate.canRead(requester, resourcePath);
    if (!allowed) {
      throw PermissionDeniedException(
        requester: requester,
        resource: resourcePath,
        action: PermissionType.read,
      );
    }

    // Check cache first
    if (_cache.containsKey(key)) return true;

    // Check disk
    return await execute<bool>(
      action: StepType.check,
      target: 'exists: $key',
      task: () async => _getFile(key).exists(),
      metadata: {'requester': requester},
    );
  }

  /// List keys with prefix (requires read permission on vault root)
  Future<List<String>> listKeys(String? prefix,
      {required String requester}) async {
    await _initVault();

    // PERMISSION CHECK - Need read access to vault root for listing
    final allowed = await _gate.canRead(requester, 'vault');
    if (!allowed) {
      throw PermissionDeniedException(
        requester: requester,
        resource: 'vault',
        action: PermissionType.read,
      );
    }

    return await execute<List<String>>(
      action: StepType.fetch,
      target: 'listing keys${prefix != null ? " with prefix: $prefix" : ""}',
      task: () async {
        final files = _vaultDir!.listSync();
        final keys =
            files.whereType<File>().map((f) => p.basename(f.path)).toList();

        if (prefix != null) {
          return keys.where((k) => k.startsWith(prefix)).toList();
        }
        return keys;
      },
      metadata: {'requester': requester},
    );
  }

  /// Clear all cached data (requires delete permission on vault root)
  Future<void> clearAll({required String requester}) async {
    await _initVault();

    // PERMISSION CHECK - Need delete access to vault root
    final result = await _gate.requestAccess(
      requester: requester,
      requesterType: GranteeType.agent,
      resourcePath: 'vault',
      action: PermissionType.delete,
    );

    if (result != AccessResult.allowed) {
      throw PermissionDeniedException(
        requester: requester,
        resource: 'vault',
        action: PermissionType.delete,
      );
    }

    await execute(
        action: StepType.modify,
        target: 'clearing vault',
        task: () async {
          if (_vaultDir!.existsSync()) {
            _vaultDir!.deleteSync(recursive: true);
            _vaultDir!.createSync();
          }
          _cache.clear();
        },
        metadata: {'requester': requester});
  }

  /// Get the access gate for external use
  AccessGate get accessGate => _gate;
}

/// Storage operations
enum StorageOperation {
  save,
  load,
  delete,
  exists,
  list,
}

/// Request for storage operation
class StorageRequest {
  final StorageOperation operation;
  final String key;
  final dynamic value;
  final String? prefix;
  final String? requester; // NEW: Who is making this request

  const StorageRequest({
    required this.operation,
    required this.key,
    this.value,
    this.prefix,
    this.requester,
  });

  /// Create a save request
  factory StorageRequest.save(String key, dynamic value,
          {required String requester}) =>
      StorageRequest(
          operation: StorageOperation.save,
          key: key,
          value: value,
          requester: requester);

  /// Create a load request
  factory StorageRequest.load(String key, {required String requester}) =>
      StorageRequest(
          operation: StorageOperation.load, key: key, requester: requester);

  /// Create a delete request
  factory StorageRequest.delete(String key, {required String requester}) =>
      StorageRequest(
          operation: StorageOperation.delete, key: key, requester: requester);
}
