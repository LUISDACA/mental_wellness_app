class SosContact {
  final String id;
  final String label;
  final String? phone;
  final String? email;

  SosContact({required this.id, required this.label, this.phone, this.email});

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
