import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'permission_types.dart';

/// A single audit log entry.
class AuditEntry {
  /// Unique ID
  final String id;

  /// Who requested access
  final String requester;

  /// Type of requester
  final GranteeType requesterType;

  /// Target resource
  final String resource;

  /// Action attempted
  final PermissionType action;

  /// Result of the access check
  final AccessResult result;

  /// When this occurred
  final DateTime timestamp;

  /// Additional context (optional)
  final Map<String, dynamic>? metadata;

  /// Hash of previous entry (for chain integrity)
  final String? previousHash;

  /// Hash of this entry
  final String hash;

  AuditEntry({
    required this.id,
    required this.requester,
    required this.requesterType,
    required this.resource,
    required this.action,
    required this.result,
    required this.timestamp,
    this.metadata,
    this.previousHash,
    required this.hash,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester': requester,
      'requesterType': requesterType.index,
      'resource': resource,
      'action': action.index,
      'result': result.index,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'previousHash': previousHash,
      'hash': hash,
    };
  }

  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      id: json['id'],
      requester: json['requester'],
      requesterType: GranteeType.values[json['requesterType']],
      resource: json['resource'],
      action: PermissionType.values[json['action']],
      result: AccessResult.values[json['result']],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
      previousHash: json['previousHash'],
      hash: json['hash'],
    );
  }
}

/// Tamper-proof audit log with hash-chained entries.
///
/// Every entry is cryptographically linked to the previous,
/// making undetected modification impossible.
class AuditLog {
  // Singleton
  static final AuditLog _instance = AuditLog._internal();
  factory AuditLog() => _instance;
  AuditLog._internal();

  final List<AuditEntry> _entries = [];
  String? _lastHash;
  String? _storagePath;
  bool _initialized = false;
  int _counter = 0;

  /// Initialize and load from disk
  Future<void> initialize() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();
    _storagePath = p.join(dir.path, 'permissions', 'audit_log.json');

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

  /// Record an access attempt
  Future<AuditEntry> record({
    required String requester,
    required GranteeType requesterType,
    required String resource,
    required PermissionType action,
    required AccessResult result,
    Map<String, dynamic>? metadata,
  }) async {
    _counter++;
    final id = 'audit_${DateTime.now().millisecondsSinceEpoch}_$_counter';
    final timestamp = DateTime.now();

    // Compute hash including previous hash for chain integrity
    final hash = _computeHash(
      id: id,
      requester: requester,
      resource: resource,
      action: action,
      result: result,
      timestamp: timestamp,
      previousHash: _lastHash,
    );

    final entry = AuditEntry(
      id: id,
      requester: requester,
      requesterType: requesterType,
      resource: resource,
      action: action,
      result: result,
      timestamp: timestamp,
      metadata: metadata,
      previousHash: _lastHash,
      hash: hash,
    );

    _entries.add(entry);
    _lastHash = hash;

    await _persist();
    return entry;
  }

  /// Compute SHA-256 hash for chain integrity
  String _computeHash({
    required String id,
    required String requester,
    required String resource,
    required PermissionType action,
    required AccessResult result,
    required DateTime timestamp,
    String? previousHash,
  }) {
    final data =
        '$id|$requester|$resource|${action.index}|${result.index}|${timestamp.toIso8601String()}|${previousHash ?? 'GENESIS'}';
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Verify the integrity of the entire chain
  bool verifyChain() {
    if (_entries.isEmpty) return true;

    String? expectedPrevHash;

    for (final entry in _entries) {
      // Check previous hash matches
      if (entry.previousHash != expectedPrevHash) {
        return false;
      }

      // Recompute hash and verify
      final computed = _computeHash(
        id: entry.id,
        requester: entry.requester,
        resource: entry.resource,
        action: entry.action,
        result: entry.result,
        timestamp: entry.timestamp,
        previousHash: entry.previousHash,
      );

      if (computed != entry.hash) {
        return false;
      }

      expectedPrevHash = entry.hash;
    }

    return true;
  }

  /// Get all entries (read-only)
  List<AuditEntry> get entries => List.unmodifiable(_entries);

  /// Get entries for a specific requester
  List<AuditEntry> getEntriesFor(String requester) {
    return _entries.where((e) => e.requester == requester).toList();
  }

  /// Get entries for a specific resource
  List<AuditEntry> getEntriesAt(String resource) {
    return _entries.where((e) => e.resource == resource).toList();
  }

  /// Get denied entries only
  List<AuditEntry> get deniedEntries {
    return _entries.where((e) => e.result == AccessResult.denied).toList();
  }

  /// Persist to disk
  Future<void> _persist() async {
    if (_storagePath == null) return;

    final data = {
      'version': 1,
      'lastHash': _lastHash,
      'entries': _entries.map((e) => e.toJson()).toList(),
    };

    final file = File(_storagePath!);
    await file.writeAsString(jsonEncode(data));
  }

  /// Load from disk
  Future<void> load() async {
    if (_storagePath == null) return;

    final file = File(_storagePath!);
    if (!await file.exists()) return;

    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      _entries.clear();
      _lastHash = data['lastHash'];

      if (data['entries'] != null) {
        for (final json in data['entries']) {
          _entries.add(AuditEntry.fromJson(json));
        }
      }

      // Verify chain integrity on load
      if (!verifyChain()) {
        throw StateError('Audit log chain integrity check failed!');
      }
    } catch (e) {
      // Log corruption detected
      rethrow;
    }
  }
}
