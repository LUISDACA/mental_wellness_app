import 'package:flutter/material.dart';

class ContactFields extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController addressController;

  const ContactFields({
    super.key,
    required this.phoneController,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: addressController,
          decoration: const InputDecoration(
            labelText: 'Dirección',
            prefixIcon: Icon(Icons.home_outlined),
          ),
        ),
      ],
    );
  }
}