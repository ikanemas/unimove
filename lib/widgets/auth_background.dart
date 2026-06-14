import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class AuthBackground extends StatelessWidget {

  final Widget child;


  const AuthBackground({
    super.key,
    required this.child,
  });


  @override
  Widget build(BuildContext context) {

    return Container(

      decoration: const BoxDecoration(

        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],

          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),

      child: SafeArea(
        child: child,
      ),
    );
  }
}