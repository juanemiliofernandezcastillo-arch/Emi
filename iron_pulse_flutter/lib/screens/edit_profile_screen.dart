import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final Color bgLight = const Color(0xFFF8FAFC);
  final Color bgDark = const Color(0xFF0F1115);
  final Color cardLight = const Color(0xFFFFFFFF);
  final Color cardDark = const Color(0xFF1A1D23);
  final Color primaryColor = const Color(0xFF14B8DB);

  bool _isLoading = true;
  bool _isSaving = false;
  Profile? _profile;
  String? _email;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dobController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _dobController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _profile = await ProfileService().getCurrentProfile();
    final user = Supabase.instance.client.auth.currentUser;
    _email = user?.email;

    if (_profile != null) {
      _nameController.text = _profile!.fullName ?? '';
      _emailController.text = _email ?? '';
      _phoneController.text = _profile!.phone ?? '';
      _dobController.text = _profile!.dateOfBirth ?? '';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isLoading = true);

      if (_profile != null) {
        final newAvatarUrl = await ProfileService().uploadAvatar(_profile!.id, image);
        if (newAvatarUrl != null) {
          await _loadData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Foto actualizada correctamente')),
            );
          }
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al subir la imagen')),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    surface: cardDark,
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    surface: cardLight,
                    onSurface: Colors.black,
                  ),
            dialogBackgroundColor: isDark ? cardDark : cardLight,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('MMMM d, yyyy').format(picked);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_profile == null) return;

    setState(() => _isSaving = true);

    try {
      // Create an updated profile object
      final updatedProfile = _profile!.copyWith(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        dateOfBirth: _dobController.text.trim(),
      );

      // Attempt to save to Supabase
      await ProfileService().updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to profile screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? bgDark : bgLight;
    final cardBgColor = isDark ? cardDark : cardLight;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark ? const Color(0xFF64748B) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isDark ? cardBgColor : const Color(0xFFE2E8F0),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              "Edit Profile",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 120),
                          child: Column(
                            children: [
                              // Profile Info Section
                              Stack(
                                alignment: Alignment.topCenter,
                                children: [
                                  // Gradient Background
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          primaryColor.withOpacity(0.1),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      const SizedBox(height: 32),
                                      // Avatar
                                      GestureDetector(
                                        onTap: _pickAndUploadImage,
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: 128,
                                              height: 128,
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: primaryColor.withOpacity(0.2), width: 4),
                                              ),
                                              child: ClipOval(
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    _profile?.avatarUrl != null
                                                        ? Image.network(
                                                            _profile!.avatarUrl!,
                                                            fit: BoxFit.cover,
                                                            color: Colors.black.withOpacity(0.25),
                                                            colorBlendMode: BlendMode.darken,
                                                          )
                                                        : Image.network(
                                                            'https://ui-avatars.com/api/?name=${_profile?.fullName ?? 'U'}&background=14b8db&color=fff',
                                                            fit: BoxFit.cover,
                                                            color: Colors.black.withOpacity(0.25),
                                                            colorBlendMode: BlendMode.darken,
                                                          ),
                                                    Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.photo_camera, color: Colors.white, size: 32),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          "EDIT PHOTO",
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                            letterSpacing: 1.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Form Fields
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      label: "Full Name",
                                      controller: _nameController,
                                      textColor: textColor,
                                      mutedTextColor: mutedTextColor,
                                      cardBgColor: cardBgColor,
                                      borderColor: borderColor,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildTextField(
                                      label: "Email Address",
                                      controller: _emailController,
                                      textColor: textColor,
                                      mutedTextColor: mutedTextColor,
                                      cardBgColor: cardBgColor,
                                      borderColor: borderColor,
                                      enabled: false, // Don't allow changing email easily
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildTextField(
                                      label: "Phone Number",
                                      controller: _phoneController,
                                      textColor: textColor,
                                      mutedTextColor: mutedTextColor,
                                      cardBgColor: cardBgColor,
                                      borderColor: borderColor,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 24),
                                    _buildTextField(
                                      label: "Date of Birth",
                                      controller: _dobController,
                                      textColor: textColor,
                                      mutedTextColor: mutedTextColor,
                                      cardBgColor: cardBgColor,
                                      borderColor: borderColor,
                                      icon: Icons.calendar_today,
                                      readOnly: true,
                                      onTap: () => _selectDate(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Save Changes Button
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 16,
                      bottom: 40 + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          bgColor,
                          bgColor.withOpacity(0.95),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: GestureDetector(
                      onTap: _isSaving ? null : _saveChanges,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required Color textColor,
    required Color mutedTextColor,
    required Color cardBgColor,
    required Color borderColor,
    bool enabled = true,
    bool readOnly = false,
    TextInputType? keyboardType,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: mutedTextColor,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  readOnly: readOnly,
                  onTap: onTap,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(icon, color: mutedTextColor, size: 20),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
