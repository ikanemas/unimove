import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AuthButton extends StatelessWidget {

  final String text;
  final VoidCallback onPressed;
  final Color? color;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: double.infinity,
      height: 55,

      child: ElevatedButton(

        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.orange,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),

        onPressed: onPressed,

        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}