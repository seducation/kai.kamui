class Profile {
  final String id;
  final String name;
  final String type;
  final String? bio;
  final String? profileImageUrl;
  final String ownerId;

  Profile({
    required this.id,
    required this.name,
    required this.type,
    this.bio,
    this.profileImageUrl,
    required this.ownerId,
  });

  factory Profile.fromMap(Map<String, dynamic> map, String id) {
    return Profile(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'profile', // Default to profile
      bio: map['bio'],
      profileImageUrl: map['profileImageUrl'],
      ownerId: map['ownerId'] ?? '',
    );
  }
}
