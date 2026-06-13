import 'package:flutter/material.dart';
import '../theme/app_colors.dart';


class ForgotPasswordPage extends StatefulWidget {

  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() =>
      _ForgotPasswordPageState();

}


class _ForgotPasswordPageState
    extends State<ForgotPasswordPage> {


  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController =
      TextEditingController();


  @override
  void dispose() {

    emailController.dispose();

    super.dispose();

  }


  void resetPassword() {

    if (_formKey.currentState!.validate()) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text(
            "Password reset link sent",
          ),

        ),

      );

    }

  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

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

          child: Padding(

            padding: const EdgeInsets.all(25),

            child: Form(

              key: _formKey,

              child: Column(

                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [

                  const Icon(

                    Icons.lock_reset,

                    size: 90,

                    color: AppColors.gold,

                  ),


                  const SizedBox(height: 20),


                  const Text(

                    "Forgot Password",

                    style: TextStyle(

                      color: Colors.white,

                      fontSize: 32,

                      fontWeight: FontWeight.bold,

                    ),

                  ),


                  const SizedBox(height: 10),


                  const Text(

                    "Enter your email to reset password",

                    textAlign: TextAlign.center,

                    style: TextStyle(

                      color: Colors.white70,

                    ),

                  ),


                  const SizedBox(height: 40),


                  TextFormField(

                    controller: emailController,

                    validator: (value) {

                      if (value == null ||
                          value.isEmpty) {

                        return "Please enter your email";

                      }

                      return null;

                    },

                    decoration: InputDecoration(

                      filled: true,

                      fillColor: Colors.white,

                      hintText: "Email",

                      prefixIcon:
                      const Icon(Icons.email),

                      border: OutlineInputBorder(

                        borderRadius:
                        BorderRadius.circular(15),

                      ),

                    ),

                  ),


                  const SizedBox(height: 30),


                  SizedBox(

                    width: double.infinity,

                    height: 55,

                    child: ElevatedButton(

                      style: ElevatedButton.styleFrom(

                        backgroundColor:
                        AppColors.orange,

                        shape:
                        RoundedRectangleBorder(

                          borderRadius:
                          BorderRadius.circular(15),

                        ),

                      ),

                      onPressed: resetPassword,

                      child: const Text(

                        "SEND RESET LINK",

                        style: TextStyle(

                          color: Colors.white,

                          fontWeight:
                          FontWeight.bold,

                        ),

                      ),

                    ),

                  ),


                  const SizedBox(height: 20),


                  TextButton(

                    onPressed: () {

                      Navigator.pop(context);

                    },

                    child: const Text(

                      "Back to Login",

                      style: TextStyle(
                        color: AppColors.gold,
                      ),

                    ),

                  ),

                ],

              ),

            ),

          ),

        ),

      ),

    );

  }

}