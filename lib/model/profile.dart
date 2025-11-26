class Profile {
  final String id;
  final String name;
  final String? bio;
  final String? imageUrl;
  final String ownerId;

  Profile({
    required this.id,
    required this.name,
    this.bio,
    this.imageUrl,
    required this.ownerId,
  });

  factory Profile.fromMap(Map<String, dynamic> map, String id) {
    return Profile(
      id: id,
      name: map['name'] ?? '',
      bio: map['bio'],
      imageUrl: map['imageUrl'],
      ownerId: map['ownerId'] ?? '',
    );
  }
}
