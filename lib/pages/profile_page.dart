import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'errand_history_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? email;
  String? role;
  String? name;
  String? phoneNumber;

  bool isLoading = true;
  bool isEditing = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => isLoading = true);

    try {
      final user = SupabaseService.client.auth.currentUser;

      if (user != null) {
        email = user.email ?? 'No email';
        name =
            user.userMetadata?['name'] ?? user.userMetadata?['full_name'] ?? '';
        role = user.userMetadata?['role'] ?? 'No role';
        phoneNumber = user.userMetadata?['phone_number'] ?? '';

        nameController.text = name ?? '';
        phoneController.text = phoneNumber ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_validateFields()) return;

    setState(() => isUpdating = true);

    try {
      final user = SupabaseService.client.auth.currentUser;

      if (user == null) {
        throw Exception('User not logged in');
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'name': nameController.text.trim(),
        'phone_number': phoneController.text.trim(),
      };

      // Update user metadata
      final updatedUser = await SupabaseService.client.auth.updateUser(
        UserAttributes(data: updateData),
      );

      // If password is being updated
      if (passwordController.text.isNotEmpty) {
        if (passwordController.text != confirmPasswordController.text) {
          throw Exception('Passwords do not match');
        }
        if (passwordController.text.length < 6) {
          throw Exception('Password must be at least 6 characters');
        }

        await SupabaseService.client.auth.updateUser(
          UserAttributes(password: passwordController.text),
        );

        // Clear password fields after update
        passwordController.clear();
        confirmPasswordController.clear();
      }

      // Update local variables
      name =
          updatedUser.user?.userMetadata?['name'] ?? nameController.text.trim();
      phoneNumber =
          updatedUser.user?.userMetadata?['phone_number'] ??
          phoneController.text.trim();

      if (!mounted) return;
      setState(() {
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadUserProfile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isUpdating = false);
    }
  }

  bool _validateFields() {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }

    if (passwordController.text.isNotEmpty &&
        passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }

    if (passwordController.text.isNotEmpty &&
        passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await SupabaseService.client.auth.signOut();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout error: ${e.toString()}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF643D),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF18074d),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF643D)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF18074d), Color(0xFF422a59)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFffc95c),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: const Color(
                                0xFFffc95c,
                              ).withValues(alpha: 0.2),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: const Color(0xFF18074d),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            name ?? 'No Name',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFffc95c,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              role ?? 'No Role',
                              style: const TextStyle(
                                color: Color(0xFFffc95c),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            email ?? 'No Email',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Profile Details
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Edit Mode Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF18074d),
                              ),
                            ),
                            if (!isEditing)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() => isEditing = true);
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Color(0xFFFF643D),
                                ),
                                label: const Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Color(0xFFFF643D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const Divider(height: 25),

                        // Name Field
                        _buildInfoRow(
                          label: 'Name',
                          icon: Icons.person_outline,
                          isEditing: isEditing,
                          controller: nameController,
                          value: name ?? 'Not set',
                        ),

                        const SizedBox(height: 15),

                        // Phone Field
                        _buildInfoRow(
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          isEditing: isEditing,
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          value: phoneNumber ?? 'Not set',
                        ),

                        const SizedBox(height: 15),

                        // Email (Non-editable)
                        _buildInfoRow(
                          label: 'Email',
                          icon: Icons.email_outlined,
                          value: email ?? 'No Email',
                          isEditing: false,
                        ),

                        const SizedBox(height: 15),

                        // Role (Non-editable)
                        _buildInfoRow(
                          label: 'Role',
                          icon: Icons.badge_outlined,
                          value: role ?? 'No Role',
                          isEditing: false,
                        ),

                        // Password change section
                        if (isEditing) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 15),

                          const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF18074d),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // New Password
                          TextFormField(
                            controller: passwordController,
                            obscureText: hidePassword,
                            decoration: InputDecoration(
                              labelText: 'New Password (Optional)',
                              hintText: 'Leave blank to keep current',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF18074d),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF18074d),
                                ),
                                onPressed: () {
                                  setState(() => hidePassword = !hidePassword);
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF643D),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Confirm Password
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: hideConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              hintText: 'Confirm your new password',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Color(0xFF18074d),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hideConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF18074d),
                                ),
                                onPressed: () {
                                  setState(
                                    () => hideConfirmPassword =
                                        !hideConfirmPassword,
                                  );
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFF643D),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Update Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      isEditing = false;
                                      passwordController.clear();
                                      confirmPasswordController.clear();
                                      nameController.text = name ?? '';
                                      phoneController.text = phoneNumber ?? '';
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    side: const BorderSide(color: Colors.grey),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: isUpdating ? null : _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF643D),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: isUpdating
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Errand History Button
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFffc95c,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.history,
                              color: Color(0xFFffc95c),
                            ),
                          ),
                          title: const Text(
                            'Errand History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF18074d),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ErrandHistoryPage(),
                              ),
                            );
                          },
                        ),

                        const Divider(),

                        // Logout Button
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout, color: Colors.red),
                          ),
                          title: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required IconData icon,
    required bool isEditing,
    TextEditingController? controller,
    String? value,
    TextInputType? keyboardType,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF422a59)),
        const SizedBox(width: 15),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(
          flex: 3,
          child: isEditing && controller != null
              ? TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter $label',
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: Color(0xFFFF643D),
                        width: 2,
                      ),
                    ),
                  ),
                )
              : Text(
                  value ?? 'Not set',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF18074d),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }
}
