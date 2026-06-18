import 'package:flutter/material.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.readOnly = false,
    this.prefixIcon,
    this.suffix,
    this.hint,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final bool readOnly;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        readOnly: readOnly,
        style: const TextStyle(color: Color(0xFFE0E0F0), fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: const Color(0xFF8888AA), size: 20)
              : null,
          suffix: suffix,
        ),
      ),
    );
  }
}
