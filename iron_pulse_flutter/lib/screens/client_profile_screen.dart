import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../app_theme.dart';
import '../models.dart';
import '../services/profile_service.dart';
import '../services/bookings_service.dart';
import '../services/supabase_auth_service.dart';
import '../home_page.dart';
import 'explore_classes_screen.dart';
import 'my_reservations_screen.dart';
import 'edit_profile_screen.dart';
import '../login_page.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final Color bgLight = const Color(0xFFF8FAFC);
  final Color bgDark = const Color(0xFF0F1115);
  final Color cardLight = const Color(0xFFFFFFFF);
  final Color cardDark = const Color(0xFF1A1D23);
  final Color primaryColor = const Color(0xFF14B8DB);

  bool _isLoading = true;
  Profile? _profile;
  int _classesCount = 0;
  int _trainedHours = 0;
  final int _badgesCount = 5; // Placeholder for now

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _profile = await ProfileService().getCurrentProfile();
    
    if (_profile != null) {
      final bookings = await BookingsService().getUserBookings(_profile!.id);
      
      int count = 0;
      int totalMinutes = 0;
      
      for (var booking in bookings) {
        if (booking.status == BookingStatus.confirmed) {
          count++;
          if (booking.schedule?.classModel != null) {
            totalMinutes += booking.schedule!.classModel!.durationMinutes;
          }
        }
      }
      
      _classesCount = count;
      _trainedHours = totalMinutes ~/ 60;
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Próximamente'),
        duration: Duration(seconds: 2),
      ),
    );
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
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error al subir la imagen. Verifica que el bucket "avatars" exista en Supabase y sea público.')),
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

  @override
  Widget build(BuildContext context) {
    // Determine theme brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? bgDark : bgLight;
    final cardBgColor = isDark ? cardDark : cardLight;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedTextColor = isDark ? const Color(0xFF64748B) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0);

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
                      // Top header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Perfil",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? cardBgColor : const Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.settings, color: textColor, size: 20),
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
                                          primaryColor.withOpacity(0.15),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      // Avatar
                                      GestureDetector(
                                        onTap: _pickAndUploadImage,
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: 112,
                                              height: 112,
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: primaryColor.withOpacity(0.3), width: 4),
                                              ),
                                              child: ClipOval(
                                                child: _profile?.avatarUrl != null
                                                    ? Image.network(
                                                        _profile!.avatarUrl!,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.network(
                                                        'https://ui-avatars.com/api/?name=${_profile?.fullName ?? 'U'}&background=14b8db&color=fff',
                                                        fit: BoxFit.cover,
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 4,
                                              right: 4,
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: primaryColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: bgColor, width: 2),
                                                ),
                                                child: const Icon(Icons.edit, color: Colors.white, size: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Name
                                      Text(
                                        _profile?.fullName ?? 'Usuario',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Membership Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.amber.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.stars, color: Colors.amber, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              "GOLD MEMBER",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.amber,
                                                letterSpacing: 1.0,
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
                              
                              // Stats Cards
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: cardBgColor,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatItem(_classesCount.toString(), "Clases", textColor, mutedTextColor),
                                      Container(width: 1, height: 32, color: borderColor),
                                      _buildStatItem("${_trainedHours}h", "Entrenado", textColor, mutedTextColor),
                                      Container(width: 1, height: 32, color: borderColor),
                                      _buildStatItem(_badgesCount.toString(), "Medallas", textColor, mutedTextColor),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Menu Options
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                                      child: Text(
                                        "AJUSTES DE CUENTA",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: mutedTextColor,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                    _buildMenuItem(
                                      icon: Icons.person,
                                      iconColor: primaryColor,
                                      title: "Información Personal",
                                      cardBgColor: cardBgColor,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                        );
                                        // Reload data when coming back from EditProfileScreen
                                        _loadData();
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    _buildMenuItem(
                                      icon: Icons.payment,
                                      iconColor: Colors.purple,
                                      title: "Membresía y Facturación",
                                      cardBgColor: cardBgColor,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      onTap: _showComingSoon,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildMenuItem(
                                      icon: Icons.history,
                                      iconColor: Colors.orange,
                                      title: "Historial de Entrenamiento",
                                      cardBgColor: cardBgColor,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      onTap: _showComingSoon,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildMenuItem(
                                      icon: Icons.notifications_active,
                                      iconColor: Colors.blue,
                                      title: "Notificaciones",
                                      cardBgColor: cardBgColor,
                                      borderColor: borderColor,
                                      textColor: textColor,
                                      onTap: _showComingSoon,
                                    ),
                                    
                                    const SizedBox(height: 16),
                                    
                                    // Log Out Button
                                    GestureDetector(
                                      onTap: () async {
                                        await SupabaseAuthService().signOut();
                                        if (context.mounted) {
                                          Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(builder: (_) => const LoginPage()),
                                            (route) => false,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: Colors.red.withOpacity(0.2)),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: const Icon(Icons.logout, color: Colors.red),
                                            ),
                                            const SizedBox(width: 16),
                                            const Text(
                                              "Cerrar Sesión",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 16,
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildBottomNav(isDark, bgColor, borderColor),
              ],
            ),
    );
  }

  Widget _buildStatItem(String value, String label, Color textColor, Color mutedTextColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: mutedTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color cardBgColor,
    required Color borderColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: borderColor == const Color(0xFFE2E8F0) ? Colors.black26 : Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isDark, Color bgColor, Color borderColor) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 72 + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.9),
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_filled, 
                    label: "Inicio", 
                    isSelected: false, 
                    isDark: isDark,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation1, animation2) => const HomePage(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    }
                  ),
                  _buildNavItem(
                    icon: Icons.search, 
                    label: "Explorar", 
                    isSelected: false, 
                    isDark: isDark,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation1, animation2) => const ExploreClassesScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    }
                  ),
                  _buildNavItem(
                    icon: Icons.calendar_today, 
                    label: "Reservas", 
                    isSelected: false, 
                    isDark: isDark,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation1, animation2) => const MyReservationsScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    }
                  ),
                  _buildNavItem(
                    icon: Icons.person, 
                    label: "Perfil", 
                    isSelected: true, 
                    isDark: isDark,
                    onTap: () {}
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isSelected, required bool isDark, required VoidCallback onTap}) {
    final color = isSelected ? primaryColor : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8));
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: isSelected ? const EdgeInsets.symmetric(horizontal: 24, vertical: 4) : const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 10)] : [],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
