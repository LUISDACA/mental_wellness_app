class Profile {
  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String? gender; // 'female' | 'male' | 'custom'
  final DateTime? birthDate; // DATE en DB
  final String? phone;
  final String? address;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.firstName,
    this.lastName,
    this.fullName,
    this.gender,
    this.birthDate,
    this.phone,
    this.address,
    this.avatarPath,
  });

  factory Profile.fromMap(Map<String, dynamic> m) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      final s = v.toString();
      try {
        return DateTime.parse(s);
      } catch (_) {
        return null;
      }
    }

    return Profile(
      id: m['id'] as String,
      email: m['email'] as String?,
      firstName: m['first_name'] as String?,
      lastName: m['last_name'] as String?,
      fullName: m['full_name'] as String?,
      gender: m['gender'] as String?,
      birthDate: parseDate(m['birth_date']),
      phone: m['phone'] as String?,
      address: m['address'] as String?,
      avatarPath: m['avatar_path'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      updatedAt: DateTime.parse(m['updated_at'] as String),
    );
  }
}
