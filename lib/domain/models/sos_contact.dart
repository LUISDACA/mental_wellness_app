class SosContact {
  final String id;
  final String label;
  final String? phone;
  final String? email;

  SosContact({
    required this.id,
    required String label,
    this.phone,
    this.email,
  }) : label = _validateLabel(label) {
    _validateContactInfo(phone, email);
  }

  /// Validates that the label is not empty
  static String _validateLabel(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Contact label cannot be empty');
    }
    return trimmed;
  }

  /// Validates that at least one contact method (phone or email) is provided
  static void _validateContactInfo(String? phone, String? email) {
    final hasPhone = phone != null && phone.trim().isNotEmpty;
    final hasEmail = email != null && email.trim().isNotEmpty;

    if (!hasPhone && !hasEmail) {
      throw ArgumentError(
        'SOS contact must have at least a phone number or email address',
      );
    }
  }

  factory SosContact.fromJson(Map<String, dynamic> json) => SosContact(
        id: json['id'] as String,
        label: json['label'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'phone': phone,
        'email': email,
      };
}
