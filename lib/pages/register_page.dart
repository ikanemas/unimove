import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/database_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String selectedRole = "Student";
  
  final _formKey = GlobalKey<FormState>();


  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  final TextEditingController phoneController =
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


void register() async {
  print("STEP 1: validate form");

  if (_formKey.currentState!.validate()) {
    print("STEP 2: calling database");

    await DatabaseService.instance.insertUser(
      nameController.text,
      emailController.text,
      passwordController.text,
      phoneController.text,
      selectedRole, 
    );

    print("STEP 3: user inserted");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account Created Successfully")),
    );

    Navigator.pop(context);
  }
}



  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      const SizedBox(height: 40),

                      const Icon(Icons.person_add,
                          size: 90, color: AppColors.gold),

                      const SizedBox(height: 20),

                      const Text(
                        "Create Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 40),

                      TextFormField(
                        controller: nameController,
                        decoration: input("Full Name", Icons.person),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: emailController,
                        decoration: input("Email", Icons.email),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        decoration: input("Password", Icons.lock).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
  controller: confirmPasswordController,
  obscureText: hideConfirmPassword,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    }

    if (value != passwordController.text) {
      return "Passwords do not match";
    }

    return null;
  },
  decoration: input("Confirm Password", Icons.lock).copyWith(
    suffixIcon: IconButton(
      icon: Icon(
        hideConfirmPassword
            ? Icons.visibility_off
            : Icons.visibility,
      ),
      onPressed: () {
        setState(() {
          hideConfirmPassword = !hideConfirmPassword;
        });
      },
    ),
  ),
),

                      const SizedBox(height: 20),

                      DropdownButtonFormField(
                        value: selectedRole,
                        items: const [
                          DropdownMenuItem(
                              value: "Student", child: Text("Student")),
                          DropdownMenuItem(
                              value: "Runner", child: Text("Runner")),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedRole = value!;
                          });
                        },
                        decoration: input("Role", Icons.people),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                          ),
                          onPressed: () {
                           register();
                           },
                          child: const Text(
                            "CREATE ACCOUNT",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration input(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}
