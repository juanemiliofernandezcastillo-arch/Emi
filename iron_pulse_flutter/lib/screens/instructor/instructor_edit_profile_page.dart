import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';

class InstructorEditProfilePage extends StatefulWidget {
  const InstructorEditProfilePage({super.key});

  @override
  State<InstructorEditProfilePage> createState() => _InstructorEditProfilePageState();
}

class _InstructorEditProfilePageState extends State<InstructorEditProfilePage> {
  final _bioController = TextEditingController();
  final _nameController = TextEditingController();
  final _expController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _instructorId;
  
  final List<String> _availableSpecialties = [
    'Yoga', 'CrossFit', 'Boxing', 'Pilates', 'HIIT', 'Fuerza', 'Cardio', 'Spinning'
  ];
  List<String> _selectedSpecialties = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profileRes = await Supabase.instance.client.from('profiles').select().eq('id', user.id).maybeSingle();
      if (profileRes != null) {
         _nameController.text = profileRes['full_name'] ?? '';
      }

      final instructorRes = await Supabase.instance.client.from('instructors').select().eq('id', user.id).maybeSingle();
      if (instructorRes != null) {
        _instructorId = instructorRes['id'];
        _bioController.text = instructorRes['bio'] ?? '';
        _nameController.text = instructorRes['name'] ?? _nameController.text;
        _expController.text = (instructorRes['years_of_experience'] ?? '').toString();
        
        if (instructorRes['specialties'] != null) {
          _selectedSpecialties = List<String>.from(instructorRes['specialties']);
        }
      } else {
        _instructorId = user.id;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('instructors').upsert({
          'id': _instructorId ?? user.id,
          'name': _nameController.text,
          'bio': _bioController.text,
          'years_of_experience': int.tryParse(_expController.text),
          'specialties': _selectedSpecialties,
        });

        await Supabase.instance.client.from('profiles').update({
          'full_name': _nameController.text,
        }).eq('id', user.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado correctamente')),
          );
        }
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar el perfil')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  void _toggleSpecialty(String spec) {
    setState(() {
      if (_selectedSpecialties.contains(spec)) {
        _selectedSpecialties.remove(spec);
      } else {
        _selectedSpecialties.add(spec);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFf1f2f4), // Light background placeholder if needed
      body: Container(
        color: AppTheme.background, // Dark background
        child: Stack(
          children: [
            // Background Blur Blobs
            Positioned(
              top: -size.height * 0.1,
              left: -size.width * 0.2,
              width: size.width * 0.8,
              height: size.height * 0.6,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.1),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              right: -size.width * 0.1,
              width: size.width * 0.6,
              height: size.height * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.05),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),

            // Scrollable Content
            SingleChildScrollView(
              child: Column(
                children: [
                  // Header Image Section
                  SizedBox(
                    height: size.height * 0.35,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuBiZQz0Kxc9Bqx0Rz8CE2KTKcANCmqYS_Q0LR82WYCYE1ZZOzMMXLt1D6q61ATjrRBYjSZo_UWaImh1x-gPhnNOC08ivC4k4PsWzCxd1J7sL-m6v64PZS7xFPH0m6_zJ88V81ScnM7zjpCBlU4UOvjkBFBVXDohLLuh25QsUxRT55ROeHVogmxDCw3Afq_W1neA7m_F_fdTbmvBztOKQbLvRr81WjlX1cmJlcMRCuyjroswLsPlqnUF90xVrf21n4m_Qz2wJ5ART6im',
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Gradients
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.background.withOpacity(0.3),
                                  AppTheme.background.withOpacity(0.6),
                                  AppTheme.background,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppTheme.background,
                                  Colors.transparent,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Top Bar
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 16,
                          left: 24,
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.fitness_center, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "IRON PULSE",
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 16,
                          right: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.admin_panel_settings, color: AppTheme.primary, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  "INSTRUCTOR",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Section
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                              children: const [
                                TextSpan(text: "Editar Mi\n"),
                                TextSpan(
                                  text: "Perfil.",
                                  style: TextStyle(color: AppTheme.primary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Actualiza la información de tu perfil.",
                            style: GoogleFonts.spaceGrotesk(
                              color: AppTheme.textMuted,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Form
                          _buildInputField(
                            label: "Nombre Completo",
                            hint: "Ej. Sarah Connor",
                            icon: Icons.person,
                            controller: _nameController,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            label: "Biografía Profesional",
                            hint: "Breve descripción de tu experiencia y filosofía...",
                            icon: Icons.description,
                            controller: _bioController,
                            maxLines: 4,
                          ),
                          const SizedBox(height: 20),
                          _buildInputField(
                            label: "Años de Experiencia",
                            hint: "Ej. 5",
                            icon: Icons.history_edu,
                            controller: _expController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          
                          // Specialties
                          Text(
                            "Especialidades",
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableSpecialties.map((spec) {
                              final isSelected = _selectedSpecialties.contains(spec);
                              return GestureDetector(
                                onTap: () => _toggleSpecialty(spec),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surface,
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primary : AppTheme.surface,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        spec,
                                        style: GoogleFonts.spaceGrotesk(
                                          color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        isSelected ? Icons.close : Icons.add,
                                        size: 16,
                                        color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Save Button
                          ElevatedButton(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8,
                              shadowColor: AppTheme.primary.withOpacity(0.5),
                            ),
                            child: _isSaving
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Guardar Perfil",
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward),
                                    ],
                                  ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Cancel/Logout Button
                          Center(
                            child: TextButton.icon(
                              onPressed: () async {
                                await Supabase.instance.client.auth.signOut();
                              },
                              icon: const Icon(Icons.logout, color: AppTheme.textMuted, size: 18),
                              label: Text(
                                "Cerrar sesión",
                                style: GoogleFonts.spaceGrotesk(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
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

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: GoogleFonts.spaceGrotesk(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.spaceGrotesk(color: AppTheme.textMuted.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 1),
              ),
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: maxLines == 1
                  ? Icon(icon, color: AppTheme.textMuted)
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Align(
                        alignment: Alignment.topRight,
                        heightFactor: 1,
                        widthFactor: 1,
                        child: Icon(icon, color: AppTheme.textMuted),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
