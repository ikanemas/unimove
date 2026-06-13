import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();


  bool hidePassword = true;
  bool hideConfirmPassword = true;


  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }


  void register() {

    if (_formKey.currentState!.validate()) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account Created Successfully"),
        ),
      );

      Navigator.pop(context);
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

          child: SingleChildScrollView(

            padding: const EdgeInsets.all(25),

            child: Form(

              key: _formKey,

              child: Column(

                children: [

                  const SizedBox(height: 50),

                  const Icon(
                    Icons.person_add,
                    size: 90,
                    color: AppColors.gold,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Create your new account",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 40),


                  // Full Name
                  TextFormField(
                    controller: nameController,

                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your name";
                      }
                      return null;
                    },

                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "Full Name",

                      prefixIcon: const Icon(Icons.person),

                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(15),
                      ),
                    ),
                  ),


                  const SizedBox(height: 20),


                  // Email
                  TextFormField(

                    controller: emailController,

                    keyboardType:
                    TextInputType.emailAddress,

                    validator: (value) {

                      if (value == null || value.isEmpty) {
                        return "Please enter your email";
                      }

                      if (!value.contains("@")) {
                        return "Invalid email address";
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


                  const SizedBox(height: 20),


                  // Password
                  TextFormField(

                    controller: passwordController,

                    obscureText: hidePassword,

                    validator: (value) {

                      if (value == null || value.isEmpty) {
                        return "Enter your password";
                      }

                      if (value.length < 6) {
                        return "Minimum 6 characters";
                      }

                      return null;

                    },

                    decoration: InputDecoration(

                      filled: true,
                      fillColor: Colors.white,

                      hintText: "Password",

                      prefixIcon:
                      const Icon(Icons.lock),

                      suffixIcon: IconButton(

                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),

                        onPressed: () {

                          setState(() {
                            hidePassword = !hidePassword;
                          });

                        },

                      ),

                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(15),
                      ),

                    ),

                  ),


                  const SizedBox(height: 20),


                  // Confirm Password
                  TextFormField(

                    controller: confirmPasswordController,

                    obscureText: hideConfirmPassword,

                    validator: (value) {

                      if (value != passwordController.text) {
                        return "Password does not match";
                      }

                      return null;

                    },

                    decoration: InputDecoration(

                      filled: true,
                      fillColor: Colors.white,

                      hintText: "Confirm Password",

                      prefixIcon:
                      const Icon(Icons.lock),

                      suffixIcon: IconButton(

                        icon: Icon(
                          hideConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),

                        onPressed: () {

                          setState(() {
                            hideConfirmPassword =
                            !hideConfirmPassword;
                          });

                        },

                      ),

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

                        shape: RoundedRectangleBorder(

                          borderRadius:
                          BorderRadius.circular(15),

                        ),

                      ),

                      onPressed: register,

                      child: const Text(

                        "CREATE ACCOUNT",

                        style: TextStyle(

                          color: Colors.white,

                          fontWeight: FontWeight.bold,

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

                      "Already have an account? Login",

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