import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../models.dart';
import '../services/bookings_service.dart';
import '../services/supabase_auth_service.dart';
import '../services/profile_service.dart';
import 'admin_students_screen.dart';
import 'admin/manage_class_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color primary = const Color(0xFF17A1CF);
  final Color primaryDark = const Color(0xFF1282A8);
  final Color bgDark = const Color(0xFF121416);
  final Color surfaceDark = const Color(0xFF1A1D21);
  final Color secondaryDark = const Color(0xFF23262B);
  final Color accentGreen = const Color(0xFF0BDA57);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate700 = const Color(0xFF334155);
  final Color slate800 = const Color(0xFF1E293B);

  Map<String, dynamic> _metrics = {
    'scheduled_classes': 0,
    'occupancy_rate': 0.0,
    'total_students': 0,
    'active_types': 0,
    'happening_now_class': null,
    'happening_now_booked': 0,
  };
  bool _isLoading = true;
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _profile = await ProfileService().getCurrentProfile();
    _metrics = await BookingsService().getAdminDashboardMetrics();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primary))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: primary,
                backgroundColor: surfaceDark,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildTopAppBar(),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildStatsGrid(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildHappeningNowCard(),
                          const SizedBox(height: 100), // padding for bottom nav
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: bgDark.withOpacity(0.9),
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.transparent, width: 2),
                          image: DecorationImage(
                            image: _profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty
                                ? NetworkImage(_profile!.avatarUrl!)
                                : const NetworkImage('https://ui-avatars.com/api/?name=Admin&background=17A1CF&color=fff'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: accentGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: bgDark, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "BIENVENIDO",
                        style: TextStyle(
                          color: slate400,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Admin Portal",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: surfaceDark,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                  ]
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.notifications, color: Colors.white, size: 20),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
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
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMainStatCard(
                icon: Icons.calendar_today,
                title: "Clases Programadas",
                value: _metrics['scheduled_classes'].toString(),
                badgeText: "Hoy",
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOccupancyCard(
                value: (_metrics['occupancy_rate'] as double).toStringAsFixed(0),
                trend: "5%",
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                title: "ESTUDIANTES TOTALES",
                value: _metrics['total_students'].toString(),
                trend: "+12%",
                trendColor: accentGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMiniStatCard(
                title: "TIPOS ACTIVOS",
                value: _metrics['active_types'].toString(),
                suffix: "tipos",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainStatCard({required IconData icon, required String title, required String value, required String badgeText}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: slate800.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: slate800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(color: slate400, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: slate400, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyCard({required String value, required String trend}) {
    double percentage = double.tryParse(value) ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: slate800.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.pie_chart, color: primary, size: 20),
              ),
              Row(
                children: [
                  Icon(Icons.trending_up, color: accentGreen, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: TextStyle(color: accentGreen, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1),
              ),
              Text(
                "%",
                style: TextStyle(color: slate400, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: slate700,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (percentage / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Tasa de Ocupación",
            style: TextStyle(color: slate400, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard({required String title, required String value, String? trend, Color? trendColor, String? suffix}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: slate800.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: slate400, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1),
              ),
              const SizedBox(width: 8),
              if (trend != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    trend,
                    style: TextStyle(color: trendColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    suffix,
                    style: TextStyle(color: slate400, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "ACCIONES RÁPIDAS",
            style: TextStyle(color: slate500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageClassScreen())).then((_) => _loadData());
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      const Text("Crear Clase", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Navigate to schedule/calendar or show a message
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Calendario próximamente!')));
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: secondaryDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: slate700),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, color: slate400, size: 20),
                      const SizedBox(width: 8),
                      const Text("Calendario", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHappeningNowCard() {
    final ClassSchedule? schedule = _metrics['happening_now_class'];
    if (schedule == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "EN CURSO AHORA",
              style: TextStyle(color: slate500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: secondaryDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: slate800),
            ),
            child: const Center(
              child: Text(
                "No hay clases en vivo en este momento",
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ),
        ],
      );
    }

    final classModel = schedule.classModel;
    final int booked = _metrics['happening_now_booked'] ?? 0;
    final int capacity = schedule.capacity;
    final timeFormat = DateFormat('h:mm a');
    final timeRange = "${timeFormat.format(schedule.startTime)} - ${timeFormat.format(schedule.endTime)}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "EN CURSO AHORA",
                style: TextStyle(color: slate500, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              Text(
                "Ver Todas",
                style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: secondaryDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: slate800),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Image Header
              SizedBox(
                height: 128,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      (classModel?.imageUrl != null && classModel!.imageUrl!.isNotEmpty)
                          ? classModel.imageUrl!
                          : 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: secondaryDark,
                          child: const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.white54, size: 40),
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            secondaryDark,
                            secondaryDark.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "LIVE",
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                classModel?.name ?? 'Sesión de Clase',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.schedule, color: slate400, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeRange,
                                    style: TextStyle(color: slate400, fontSize: 14),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: slate800,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: slate700),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                booked.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "/$capacity",
                                style: TextStyle(color: slate400, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF334155)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Avatar stack placeholder
                        Row(
                          children: [
                            _buildAvatarOverlap('https://ui-avatars.com/api/?name=John&background=random', 0),
                            _buildAvatarOverlap('https://ui-avatars.com/api/?name=Jane&background=random', 1),
                            _buildAvatarOverlap('https://ui-avatars.com/api/?name=Alex&background=random', 2),
                            Transform.translate(
                              offset: const Offset(-24, 0),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: slate800,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: secondaryDark, width: 2),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "+${(booked - 3).clamp(0, 99)}",
                                  style: TextStyle(color: slate400, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStudentsScreen()));
                          },
                          child: Text(
                            "Gestionar Clase",
                            style: TextStyle(color: primary, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarOverlap(String url, int index) {
    return Transform.translate(
      offset: Offset(-8.0 * index, 0),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: secondaryDark, width: 2),
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: surfaceDark,
        border: Border(top: BorderSide(color: slate800)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.dashboard, "Inicio", true, () {}),
              _buildNavItem(Icons.fitness_center, "Clases", false, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageClassScreen())).then((_) => _loadData());
              }),
              _buildNavItem(Icons.group, "Usuarios", false, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStudentsScreen()));
              }),
              _buildNavItem(Icons.settings, "Ajustes", false, () {
                // Config
              }),
              _buildNavItem(Icons.logout, "Salir", false, () async {
                await SupabaseAuthService().signOut();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    final color = isSelected ? primary : slate400;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 26),
                if (isSelected)
                  Positioned(
                    bottom: -8,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
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

