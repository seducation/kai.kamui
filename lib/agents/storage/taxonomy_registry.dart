import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'taxonomy_model.dart';

/// Registry for managing storage zones (vaults).
///
/// Handles both system-defined and custom zones.
class TaxonomyRegistry {
  // Singleton
  static final TaxonomyRegistry _instance = TaxonomyRegistry._internal();
  factory TaxonomyRegistry() => _instance;
  TaxonomyRegistry._internal();

  final List<StorageZone> _zones = [];
  String? _configPath;
  String? _storagePath;
  bool _initialized = false;

  /// Initialize the registry
  Future<void> initialize() async {
    if (_initialized) return;

    final docsDir = await getApplicationDocumentsDirectory();
    _storagePath = p.join(docsDir.path, 'storage');
    _configPath = p.join(docsDir.path, 'storage', 'taxonomy.json');

    await _ensureDirectoriesExist();
    await _loadConfig();
    _initialized = true;
  }

  Future<void> _ensureDirectoriesExist() async {
    // Create storage root
    final storageDir = Directory(_storagePath!);
    if (!await storageDir.exists()) {
      await storageDir.create(recursive: true);
    }

    // Create default zone directories
    for (final zone in DefaultZones.all) {
      final dir = Directory(p.join(_storagePath!, zone.name));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  Future<void> _loadConfig() async {
    _zones.clear();

    // Always include system zones
    _zones.addAll(DefaultZones.all);

    // Load custom zones
    final configFile = File(_configPath!);
    if (await configFile.exists()) {
      try {
        final content = await configFile.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        if (data['customZones'] != null) {
          for (final json in data['customZones']) {
            _zones.add(StorageZone.fromJson(json));
          }
        }
      } catch (_) {
        // Ignore corrupted config
      }
    }
  }

  Future<void> _saveConfig() async {
    final customZones = _zones.where((z) => !z.isSystem).toList();

    final data = {
      'version': 1,
      'savedAt': DateTime.now().toIso8601String(),
      'customZones': customZones.map((z) => z.toJson()).toList(),
    };

    final configFile = File(_configPath!);
    await configFile.writeAsString(jsonEncode(data));
  }

  /// Get all zones
  List<StorageZone> get allZones => List.unmodifiable(_zones);

  /// Get system zones only
  List<StorageZone> get systemZones => _zones.where((z) => z.isSystem).toList();

  /// Get custom zones only
  List<StorageZone> get customZones =>
      _zones.where((z) => !z.isSystem).toList();

  /// Find a zone by ID
  StorageZone? getZone(String id) {
    try {
      return _zones.firstWhere((z) => z.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Find a zone by path
  StorageZone? getZoneByPath(String path) {
    try {
      return _zones.firstWhere((z) => z.path == path);
    } catch (_) {
      return null;
    }
  }

  /// Add a new custom zone
  Future<StorageZone> addZone({
    required String name,
    required StorageZoneType type,
    String? parentPath,
    String? description,
    Duration? ttl,
    String icon = '📁',
  }) async {
    if (!_initialized) await initialize();

    final basePath = parentPath ?? 'storage';
    final zonePath = '$basePath/$name';

    final zone = StorageZone(
      id: 'zone_${const Uuid().v4().substring(0, 8)}',
      name: name,
      path: zonePath,
      type: type,
      description: description,
      ttl: ttl,
      icon: icon,
      isSystem: false,
    );

    // Create directory
    final dir = Directory(p.join(_storagePath!, name));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _zones.add(zone);
    await _saveConfig();

    return zone;
  }

  /// Remove a custom zone (cannot remove system zones)
  Future<bool> removeZone(String id) async {
    final zone = getZone(id);
    if (zone == null || zone.isSystem) return false;

    _zones.removeWhere((z) => z.id == id);
    await _saveConfig();

    // Optionally delete the directory
    // final dir = Directory(p.join(_storagePath!, zone.name));
    // if (await dir.exists()) await dir.delete(recursive: true);

    return true;
  }

  /// Update a zone's metadata
  Future<bool> updateZone(
    String id, {
    String? description,
    Duration? ttl,
    String? icon,
  }) async {
    final index = _zones.indexWhere((z) => z.id == id);
    if (index == -1) return false;

    final zone = _zones[index];
    _zones[index] = zone.copyWith(
      description: description ?? zone.description,
      ttl: ttl ?? zone.ttl,
      icon: icon ?? zone.icon,
    );

    await _saveConfig();
    return true;
  }

  /// Get the full file system path for a zone
  String getFullPath(StorageZone zone) {
    return p.join(_storagePath!, zone.name);
  }

  /// Add a child zone under a parent
  Future<StorageZone> addChildZone({
    required String parentId,
    required String name,
    required StorageZoneType type,
    String? description,
  }) async {
    final parent = getZone(parentId);
    if (parent == null) throw StateError('Parent zone not found');

    return await addZone(
      name: name,
      type: type,
      parentPath: parent.path,
      description: description,
    );
  }
}
