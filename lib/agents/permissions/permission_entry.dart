import 'package:uuid/uuid.dart';
import 'permission_types.dart';

/// A single permission entry in the registry.
///
/// Permissions are versioned to track changes over time.
/// Each update creates a new version linked to the previous.
class PermissionEntry {
  /// Unique identifier for this permission
  final String id;

  /// Target resource path (folder or file)
  final String resourcePath;

  /// How this permission applies (exact path or recursive)
  final PermissionScope scope;

  /// Name of the agent or model receiving permission
  final String grantee;

  /// Type of grantee (agent or model)
  final GranteeType granteeType;

  /// Set of allowed actions
  final Set<PermissionType> permissions;

  /// Optional expiration date (null = never expires)
  final DateTime? expiresAt;

  /// Who created this permission
  final String createdBy;

  /// When this permission was created
  final DateTime createdAt;

  /// Version number (incremented on each update)
  final int version;

  /// Link to previous version (for history tracking)
  final String? previousVersionId;

  PermissionEntry({
    String? id,
    required this.resourcePath,
    required this.scope,
    required this.grantee,
    required this.granteeType,
    required this.permissions,
    this.expiresAt,
    required this.createdBy,
    DateTime? createdAt,
    this.version = 1,
    this.previousVersionId,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Check if this permission has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if this permission grants a specific action
  bool grants(PermissionType type) {
    if (isExpired) return false;
    return permissions.contains(type);
  }

  /// Check if a path matches this permission's resource path
  bool matchesPath(String path) {
    if (scope == PermissionScope.exact) {
      return path == resourcePath;
    } else {
      // Recursive: path must start with resourcePath
      return path == resourcePath || path.startsWith('$resourcePath/');
    }
  }

  /// Create an updated version of this permission
  PermissionEntry copyWithNewVersion({
    String? resourcePath,
    PermissionScope? scope,
    String? grantee,
    GranteeType? granteeType,
    Set<PermissionType>? permissions,
    DateTime? expiresAt,
    required String updatedBy,
  }) {
    return PermissionEntry(
      id: const Uuid().v4(), // New ID for new version
      resourcePath: resourcePath ?? this.resourcePath,
      scope: scope ?? this.scope,
      grantee: grantee ?? this.grantee,
      granteeType: granteeType ?? this.granteeType,
      permissions: permissions ?? this.permissions,
      expiresAt: expiresAt ?? this.expiresAt,
      createdBy: updatedBy,
      version: version + 1,
      previousVersionId: id, // Link to this version
    );
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resourcePath': resourcePath,
      'scope': scope.index,
      'grantee': grantee,
      'granteeType': granteeType.index,
      'permissions': permissions.map((p) => p.index).toList(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'version': version,
      'previousVersionId': previousVersionId,
    };
  }

  /// Create from JSON
  factory PermissionEntry.fromJson(Map<String, dynamic> json) {
    return PermissionEntry(
      id: json['id'],
      resourcePath: json['resourcePath'],
      scope: PermissionScope.values[json['scope']],
      grantee: json['grantee'],
      granteeType: GranteeType.values[json['granteeType']],
      permissions: (json['permissions'] as List)
          .map((i) => PermissionType.values[i])
          .toSet(),
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(json['createdAt']),
      version: json['version'],
      previousVersionId: json['previousVersionId'],
    );
  }

  @override
  String toString() {
    return 'Permission($grantee -> $resourcePath [${permissions.map((p) => p.name).join(', ')}])';
  }
}
