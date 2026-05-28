import 'dart:ui';
import 'package:flutter/material.dart';
import '../models.dart';
import '../services/profile_service.dart';
import 'instructor_profile_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final Color bgDark = const Color(0xFF121416);
  final Color surfaceDark = const Color(0xFF1A1D21);
  final Color primaryColor = const Color(0xFF17A1CF);
  final Color textMain = const Color(0xFFE0E4EB);
  final Color textMuted = const Color(0xFF7A8490);

  bool _isLoading = true;
  List<Profile> _profiles = [];
  final Set<String> _activeUserIds = {};
  UserRole? _selectedRoleFilter;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await ProfileService().getAllProfiles();
      if (mounted) {
        setState(() {
          _profiles = profiles;
          // By default, let's make everyone active for the demo or just admins
          for (var p in _profiles) {
            _activeUserIds.add(p.id);
          }
        });
      }
    } catch (e) {
      print('Error loading profiles: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleUserActive(String id, bool isActive) {
    setState(() {
      if (isActive) {
        _activeUserIds.add(id);
      } else {
        _activeUserIds.remove(id);
      }
    });
  }

  Future<void> _changeUserRole(Profile profile, UserRole newRole) async {
    if (profile.role == newRole) return;
    
    final oldProfile = profile;
    final updatedProfile = profile.copyWith(role: newRole);

    setState(() {
      final index = _profiles.indexWhere((p) => p.id == profile.id);
      if (index != -1) {
        _profiles[index] = updatedProfile;
      }
    });

    try {
      await ProfileService().updateProfile(updatedProfile);
    } catch (e) {
      print('Error updating role: $e');
      if (mounted) {
        setState(() {
          final index = _profiles.indexWhere((p) => p.id == profile.id);
          if (index != -1) {
            _profiles[index] = oldProfile;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cambiar el rol')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : RefreshIndicator(
                      onRefresh: _loadProfiles,
                      color: primaryColor,
                      backgroundColor: surfaceDark,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 120),
                        children: [
                          _buildStatsRow(),
                          const SizedBox(height: 16),
                          _buildFilters(),
                          const SizedBox(height: 24),
                          _buildListHeader(),
                          const SizedBox(height: 12),
                          _buildUserList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Añadir usuario (Próximamente)')),
           );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: bgDark.withOpacity(0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "EDIT ROSTER",
                  style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
              children: [
                const TextSpan(text: "Gestión de\n"),
                TextSpan(text: "Usuarios", style: TextStyle(color: primaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    int enrolled = _profiles.where((p) => p.role == UserRole.client).length;
    int active = _activeUserIds.length;
    int admins = _profiles.where((p) => p.role == UserRole.admin).length;

    // Use actual counts but fallback to visual from screenshot if needed
    // In screenshot: ENROLLED 1, ACTIVE 0, ADMINS 1
    // We will use actual data so it's dynamic.

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.group,
            iconColor: primaryColor,
            label: "ENROLLED",
            value: enrolled.toString(),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF78CC33),
            label: "ACTIVE",
            value: active.toString(),
            highlight: true,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            icon: Icons.event_seat,
            iconColor: Colors.orange,
            label: "ADMINS",
            value: admins.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    String roleLabel = "All Roles";
    if (_selectedRoleFilter != null) {
      roleLabel = _selectedRoleFilter!.name.toUpperCase();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          PopupMenuButton<UserRole?>(
            initialValue: _selectedRoleFilter,
            color: surfaceDark,
            onSelected: (UserRole? role) {
              setState(() {
                _selectedRoleFilter = role;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<UserRole?>>[
              const PopupMenuItem<UserRole?>(
                value: null,
                child: Text('ALL ROLES', style: TextStyle(color: Colors.white)),
              ),
              ...UserRole.values.map((role) => PopupMenuItem<UserRole?>(
                value: role,
                child: Text(role.name.toUpperCase(), style: TextStyle(color: Colors.white)),
              )),
            ],
            child: _buildFilterButton("ROLE", roleLabel, Icons.expand_more, hasDot: _selectedRoleFilter != null),
          ),
          const SizedBox(width: 12),
          _buildFilterButton("JOINED", "Any Date", Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value, IconData icon, {bool hasDot = false}) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: bgDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          if (hasDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
          ],
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              Text(
                value,
                style: TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (!hasDot) ...[
            const SizedBox(width: 12),
            Icon(icon, color: textMuted, size: 18),
          ]
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    int active = _activeUserIds.length;
    int total = _profiles.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "USER LIST",
            style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          Text(
            "$active / $total Active",
            style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  Widget _buildUserList() {
    var filteredProfiles = _profiles;
    if (_selectedRoleFilter != null) {
      filteredProfiles = filteredProfiles.where((p) => p.role == _selectedRoleFilter).toList();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: filteredProfiles.map((profile) => _buildUserItem(profile)).toList(),
      ),
    );
  }

  Widget _buildUserItem(Profile profile) {
    final name = profile.fullName ?? 'Usuario';
    final fallbackText = "No email";
    final avatarUrl = profile.avatarUrl;
    final isActive = _activeUserIds.contains(profile.id);
    
    // Check role to color code
    final role = profile.role;
    Color roleColor = textMuted;
    if (role == UserRole.admin) {
      roleColor = primaryColor;
    } else if (role == UserRole.client) {
      roleColor = const Color(0xFF78CC33);
    } else if (role == UserRole.instructor) {
      roleColor = Colors.orange;
    }

    return GestureDetector(
      onTap: () {
        if (role == UserRole.instructor) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InstructorProfileScreen(profile: profile),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceDark,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 2),
                  image: DecorationImage(
                    image: avatarUrl != null 
                      ? NetworkImage(avatarUrl) 
                      : NetworkImage('https://ui-avatars.com/api/?name=${name[0]}&background=1A1D21&color=fff'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  decoration: BoxDecoration(color: surfaceDark, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.check_circle, color: Color(0xFF78CC33), size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profile.phone ?? fallbackText,
                  style: TextStyle(color: textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  role.name.toUpperCase(),
                  style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
          // Change role dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UserRole>(
                value: role,
                icon: Icon(Icons.arrow_drop_down, color: textMuted, size: 20),
                dropdownColor: surfaceDark,
                style: TextStyle(color: textMain, fontSize: 12, fontWeight: FontWeight.bold),
                onChanged: (UserRole? newRole) {
                  if (newRole != null) {
                    _changeUserRole(profile, newRole);
                  }
                },
                items: UserRole.values.map<DropdownMenuItem<UserRole>>((UserRole value) {
                  return DropdownMenuItem<UserRole>(
                    value: value,
                    child: Text(value.name.toUpperCase()),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    ));
  }
}
