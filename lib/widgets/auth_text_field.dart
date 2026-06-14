import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextEditingController controller;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,

      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$hint is required";
        }
        return null;
      },

      obscureText: obscure,

      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,

        hintText: hint,

        prefixIcon: Icon(icon),

        suffixIcon: suffixIcon,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}