class Profile {
  final String id; // auth.users.id
  final String? fullName;
  final String? phone;
  final String? address;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.fullName,
    this.phone,
    this.address,
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        fullName: m['full_name'] as String?,
        phone: m['phone'] as String?,
        address: m['address'] as String?,
        avatarPath: m['avatar_path'] as String?,
        createdAt: DateTime.parse(m['created_at'].toString()),
        updatedAt: DateTime.parse(m['updated_at'].toString()),
      );

  Map<String, dynamic> toUpsertMap() => {
        'id': id,
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (avatarPath != null) 'avatar_path': avatarPath,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
}
