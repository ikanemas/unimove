import 'package:flutter/material.dart';
import 'errand_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = "";
  String email = "";
  String phone = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) return;

    final db = await DatabaseService.instance.database;

    final result = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      setState(() {
        name = result.first['name'] as String;
        email = result.first['email'] as String;
        phone = result.first['phone'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF18074d);
    const secondary = Color(0xFF422a59);
    const accent = Color(0xFFff643d);
    const gold = Color(0xFFffc95c);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔥 HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: const BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              child: Column(
                children: [
                  // ICON CENTER (FIX TEPI ISSUE)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: gold,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 50, color: primary),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    name.isEmpty ? "Loading..." : name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(email, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 🔥 INFO SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: "Phone",
                    value: phone,
                    color: accent,
                  ),

                  const SizedBox(height: 25),

                  // 🔥 EDIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _editProfile,
                      icon: const Icon(Icons.edit),
                      label: const Text("Edit Profile"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: const BorderSide(color: primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ErrandHistoryPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history),
                      label: const Text("View Errand History"),
                    ),
                  ),

                  const SizedBox(height: 30),
                  SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.redAccent,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    onPressed: _logout,
    icon: const Icon(Icons.logout),
    label: const Text("Logout"),
  ),
),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    void _logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  if (!mounted) return;

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/login',
    (route) => false,
  );
}
  void _editProfile() {
    final nameController = TextEditingController(text: name);
    final phoneController = TextEditingController(text: phone);
    final passwordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Edit Profile",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF18074d),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                
                const SizedBox(height: 15),

                 TextField(
                   controller: passwordController,
                   obscureText: true,
                   decoration: const InputDecoration(
                   labelText: "New Password",
                   border: OutlineInputBorder(),
                   ),
                   ),


                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFff643d),
                    ),
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getInt('userId');

                      if (userId != null) {
                        await DatabaseService.instance.updateUser(
                          id: userId,
                          name: nameController.text,
                          email: email,
                          phone: phoneController.text,
                          password: passwordController.text.isEmpty
                            ? null
                            : passwordController.text,
                        );
                      }

                      if (!mounted) return;

                      setState(() {
                        name = nameController.text;
                        phone = phoneController.text;
                      });

                      Navigator.pop(context);
                    },
                    child: const Text("Save"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}