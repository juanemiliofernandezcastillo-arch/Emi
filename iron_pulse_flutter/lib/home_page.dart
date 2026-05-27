import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../models.dart';
import '../services/classes_service.dart';
import '../services/profile_service.dart';
import '../services/supabase_auth_service.dart';
import 'screens/class_detail_screen.dart';
import 'screens/my_reservations_screen.dart';
import 'screens/explore_classes_screen.dart';
import 'screens/client_profile_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primary = const Color(0xFF17A1CF);
  final Color primaryDark = const Color(0xFF128BB5);
  final Color bgDark = const Color(0xFF121416);
  final Color surfaceDark = const Color(0xFF1A1D21);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate700 = const Color(0xFF334155);
  final Color slate800 = const Color(0xFF1E293B);

  int _selectedFilterIndex = 0;
  List<Category> _categories = [];
  List<ClassSchedule> _schedules = [];
  Profile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _profile = await ProfileService().getCurrentProfile();
    _categories = await ClassesService().getCategories();
    
    await _loadSchedules();
  }
  
  Future<void> _loadSchedules() async {
    String? catId;
    if (_selectedFilterIndex > 0 && _selectedFilterIndex <= _categories.length) {
      catId = _categories[_selectedFilterIndex - 1].id;
    }
    _schedules = await ClassesService().getUpcomingSchedules(categoryId: catId);
    if (mounted) setState(() => _isLoading = false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildFeaturedSection(),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyFilterDelegate(
                child: _buildFilterBar(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildUpcomingClasses(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?.fullName != null ? "Hola, ${_profile!.fullName} 👋" : "Hola 👋",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "¿Listo para alcanzar tus metas hoy?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: slate400,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: slate800),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: surfaceDark, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await SupabaseAuthService().signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Clases Destacadas",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => const ExploreClassesScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      "Ver Todas",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_forward, color: primary, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 380, // Accounts for card height + shadow padding
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            children: _schedules.isNotEmpty 
              ? _schedules.take(3).map((schedule) {
                  final classModel = schedule.classModel;
                  final category = _categories.firstWhere(
                    (c) => c.id == classModel?.categoryId,
                    orElse: () => Category(id: '', name: 'CLASS', iconUrl: null)
                  );
                  final isFull = schedule.availableSpots <= 0;
                  final timeFormat = DateFormat('HH:mm');
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ClassDetailScreen(scheduleId: schedule.id)));
                      },
                      child: _buildFeaturedCard(
                        imageUrl: classModel?.imageUrl ?? 'https://via.placeholder.com/280x360',
                        badgeColor: isFull ? Colors.redAccent : const Color(0xFF78CC33),
                        badgeText: isFull ? "Llena" : "${schedule.availableSpots} Cupos",
                        badgeIcon: isFull ? Icons.block : null,
                        tagColor: primary,
                        tagText: category.name.toUpperCase(),
                        title: classModel?.name ?? 'Clase',
                        time: timeFormat.format(schedule.startTime),
                        duration: "${classModel?.durationMinutes ?? 60} min",
                        buttonText: isFull ? "Lista de Espera" : "Reservar",
                        buttonBgColor: isFull ? surfaceDark : primary,
                        buttonBorderColor: isFull ? slate700 : null,
                        buttonTextColor: isFull ? slate400 : Colors.white,
                      ),
                    ),
                  );
                }).toList() 
              : [
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No hay clases destacadas.", style: TextStyle(color: Colors.white54)),
                    ),
                  ),
                ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard({
    required String imageUrl,
    required Color badgeColor,
    required String badgeText,
    IconData? badgeIcon,
    required Color tagColor,
    required String tagText,
    required String title,
    required String time,
    required String duration,
    required String buttonText,
    required Color buttonBgColor,
    required Color buttonTextColor,
    Color? buttonBorderColor,
  }) {
    return Container(
      width: 280,
      height: 360,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  bgDark.withOpacity(0.95),
                  bgDark.withOpacity(0.6),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Top Badge
          Positioned(
            top: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: surfaceDark.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      if (badgeIcon != null) ...[
                        Icon(badgeIcon, color: badgeColor, size: 14),
                        const SizedBox(width: 6),
                      ] else ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeIcon != null ? badgeColor : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: tagColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    tagText,
                    style: TextStyle(
                      color: tagColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, color: slate400, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(color: slate400, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Container(width: 4, height: 4, decoration: BoxDecoration(color: slate500, shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Text(
                      duration,
                      style: TextStyle(color: slate400, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: buttonBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: buttonBorderColor != null ? Border.all(color: buttonBorderColor) : null,
                    boxShadow: buttonBgColor == primary
                        ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 15)]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      color: buttonTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    List<String> filterNames = ["Todas las Clases"];
    filterNames.addAll(_categories.map((e) => e.name));
    
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: bgDark.withOpacity(0.95),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: filterNames.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedFilterIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                  _loadSchedules();
                },
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? primary : slate700,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: primary.withOpacity(0.2), blurRadius: 10)]
                        : [],
                  ),
                  child: Text(
                    filterNames[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : slate400,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingClasses() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Próximas Clases",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: slate800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_schedules.length}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_schedules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("No hay próximas clases.", style: TextStyle(color: Colors.white54)),
            )
          else
            ..._schedules.map((schedule) {
              final isPast = schedule.startTime.isBefore(DateTime.now());
              final dayFormat = DateFormat('E');
              final timeFormat = DateFormat('HH:mm');
              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ClassDetailScreen(scheduleId: schedule.id)));
                    },
                    child: _buildUpcomingClassItem(
                      day: dayFormat.format(schedule.startTime),
                      time: timeFormat.format(schedule.startTime),
                      title: schedule.classModel?.name ?? 'Clase',
                      badgeText: schedule.availableSpots > 0 ? "Abierta" : "Lista de Espera",
                      badgeColor: schedule.availableSpots > 0 ? const Color(0xFF10B981) : Colors.amber,
                      badgeBgColor: schedule.availableSpots > 0 
                          ? const Color(0xFF10B981).withOpacity(0.2) 
                          : Colors.amber.withOpacity(0.2),
                      instructor: schedule.instructor?.name,
                      duration: "${schedule.classModel?.durationMinutes ?? 60}m",
                      location: schedule.locationName,
                      isPast: isPast,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildUpcomingClassItem({
    required String day,
    required String time,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBgColor,
    String? instructor,
    String? duration,
    String? location,
    bool isPast = false,
  }) {
    return Opacity(
      opacity: isPast ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 20, top: 16, bottom: 16),
        decoration: BoxDecoration(
          color: surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: slate800.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            // Date Block
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: bgDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: slate800),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.toUpperCase(),
                    style: TextStyle(
                      color: slate500,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          badgeText.toUpperCase(),
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (instructor != null) ...[
                        Icon(Icons.person, color: primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          instructor,
                          style: TextStyle(color: slate400, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (location != null) ...[
                        Icon(Icons.location_on, color: primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: TextStyle(color: slate400, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                      if (duration != null) ...[
                        const SizedBox(width: 12),
                        Container(width: 4, height: 4, decoration: BoxDecoration(color: slate700, shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Icon(Icons.timer, color: primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: TextStyle(color: slate400, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: bgDark.withOpacity(0.9),
        border: Border(top: BorderSide(color: slate800)),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home_filled, label: "Inicio", isSelected: true, onTap: () {}),
                _buildNavItem(
                  icon: Icons.search,
                  label: "Explorar",
                  isSelected: false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => const ExploreClassesScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                ),
                _buildNavItem(
                  icon: Icons.calendar_today,
                  label: "Reservas",
                  isSelected: false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => const MyReservationsScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                ),
                _buildNavItem(icon: Icons.person_outline, label: "Perfil", isSelected: false, onTap: () {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => const ClientProfileScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isSelected, required VoidCallback onTap}) {
    final color = isSelected ? primary : slate400;
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
                color: isSelected ? primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected ? [BoxShadow(color: primary.withOpacity(0.2), blurRadius: 10)] : [],
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

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyFilterDelegate({required this.child});

  @override
  double get minExtent => 68.0;

  @override
  double get maxExtent => 68.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
