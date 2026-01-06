/// Types of storage zones based on their lifecycle and purpose.
enum StorageZoneType {
  /// Temporary storage that auto-cleans after task completion
  temporary,

  /// Agent-owned isolated memory space
  agentOwned,

  /// Long-term knowledge vault (versioned, permanent)
  permanent,

  /// Speed optimization cache (disposable)
  cache,

  /// User-defined custom zone
  custom,
}

/// A storage zone in the taxonomy hierarchy.
class StorageZone {
  /// Unique identifier
  final String id;

  /// Display name
  final String name;

  /// File system path (relative to storage root)
  final String path;

  /// Type of zone
  final StorageZoneType type;

  /// Optional description
  final String? description;

  /// Time-to-live for auto-cleanup (null = permanent)
  final Duration? ttl;

  /// Child zones (for hierarchy)
  final List<StorageZone> children;

  /// Icon for UI display
  final String icon;

  /// Whether this zone is system-defined (cannot delete)
  final bool isSystem;

  const StorageZone({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.description,
    this.ttl,
    this.children = const [],
    this.icon = '📁',
    this.isSystem = false,
  });

  /// Create a child zone under this zone
  StorageZone createChild({
    required String id,
    required String name,
    required StorageZoneType type,
    String? description,
    Duration? ttl,
    String icon = '📁',
  }) {
    return StorageZone(
      id: id,
      name: name,
      path: '$path/$name',
      type: type,
      description: description,
      ttl: ttl,
      icon: icon,
    );
  }

  /// Copy with modifications
  StorageZone copyWith({
    String? id,
    String? name,
    String? path,
    StorageZoneType? type,
    String? description,
    Duration? ttl,
    List<StorageZone>? children,
    String? icon,
    bool? isSystem,
  }) {
    return StorageZone(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      description: description ?? this.description,
      ttl: ttl ?? this.ttl,
      children: children ?? this.children,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type.index,
      'description': description,
      'ttl': ttl?.inSeconds,
      'children': children.map((c) => c.toJson()).toList(),
      'icon': icon,
      'isSystem': isSystem,
    };
  }

  factory StorageZone.fromJson(Map<String, dynamic> json) {
    return StorageZone(
      id: json['id'],
      name: json['name'],
      path: json['path'],
      type: StorageZoneType.values[json['type']],
      description: json['description'],
      ttl: json['ttl'] != null ? Duration(seconds: json['ttl']) : null,
      children: (json['children'] as List?)
              ?.map((c) => StorageZone.fromJson(c))
              .toList() ??
          [],
      icon: json['icon'] ?? '📁',
      isSystem: json['isSystem'] ?? false,
    );
  }

  @override
  String toString() => 'StorageZone($name @ $path)';
}

/// Default system zones
class DefaultZones {
  static const tasks = StorageZone(
    id: 'zone_tasks',
    name: 'tasks',
    path: 'storage/tasks',
    type: StorageZoneType.temporary,
    description: 'Temporary task-scoped data (auto-cleanup)',
    ttl: Duration(hours: 24),
    icon: '⏱️',
    isSystem: true,
  );

  static const agents = StorageZone(
    id: 'zone_agents',
    name: 'agents',
    path: 'storage/agents',
    type: StorageZoneType.agentOwned,
    description: 'Agent-owned persistent memory',
    icon: '🤖',
    isSystem: true,
  );

  static const vault = StorageZone(
    id: 'zone_vault',
    name: 'vault',
    path: 'storage/vault',
    type: StorageZoneType.permanent,
    description: 'Long-term knowledge (versioned)',
    icon: '🔐',
    isSystem: true,
  );

  static const cache = StorageZone(
    id: 'zone_cache',
    name: 'cache',
    path: 'storage/cache',
    type: StorageZoneType.cache,
    description: 'Disposable speed optimization',
    ttl: Duration(hours: 1),
    icon: '⚡',
    isSystem: true,
  );

  static List<StorageZone> get all => [tasks, agents, vault, cache];
}

extension StorageZoneTypeExtension on StorageZoneType {
  String get displayName {
    switch (this) {
      case StorageZoneType.temporary:
        return 'Temporary';
      case StorageZoneType.agentOwned:
        return 'Agent-Owned';
      case StorageZoneType.permanent:
        return 'Permanent';
      case StorageZoneType.cache:
        return 'Cache';
      case StorageZoneType.custom:
        return 'Custom';
    }
  }

  String get icon {
    switch (this) {
      case StorageZoneType.temporary:
        return '⏱️';
      case StorageZoneType.agentOwned:
        return '🤖';
      case StorageZoneType.permanent:
        return '🔐';
      case StorageZoneType.cache:
        return '⚡';
      case StorageZoneType.custom:
        return '📁';
    }
  }
}
