import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models.dart';
import '../services/classes_service.dart';
import 'class_detail_screen.dart';
import 'my_reservations_screen.dart';
import '../home_page.dart';
import 'client_profile_screen.dart';

class ExploreClassesScreen extends StatefulWidget {
  const ExploreClassesScreen({super.key});

  @override
  State<ExploreClassesScreen> createState() => _ExploreClassesScreenState();
}

class _ExploreClassesScreenState extends State<ExploreClassesScreen> {
  final Color bgDark = const Color(0xFF121416);
  final Color surfaceDark = const Color(0xFF1E2329);
  final Color cardDark = const Color(0xFF1A1D21);
  final Color textMuted = const Color(0xFF7A8490);

  bool _isLoading = true;
  List<ClassSchedule> _allSchedules = [];
  List<Category> _categories = [];
  
  // Filtering state
  late DateTime _selectedDate;
  String _selectedCategoryId = "all"; // "all" for no filter
  
  // Horizontal dates strip
  final List<DateTime> _dateStrip = [];

  @override
  void initState() {
    super.initState();
    // Initialize date strip from today onwards (e.g. next 14 days)
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    for (int i = 0; i < 14; i++) {
      _dateStrip.add(_selectedDate.add(Duration(days: i)));
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Fetch upcoming classes & categories in parallel
    final results = await Future.wait([
      ClassesService().getUpcomingSchedules(),
      ClassesService().getCategories(),
    ]);

    if (mounted) {
      setState(() {
        _allSchedules = results[0] as List<ClassSchedule>;
        _categories = results[1] as List<Category>;
        _isLoading = false;
      });
    }
  }

  // Filter schedules based on selected date and category
  List<ClassSchedule> get _filteredSchedules {
    return _allSchedules.where((schedule) {
      final localStart = schedule.startTime.toLocal();
      final isSameDay = localStart.year == _selectedDate.year && 
                        localStart.month == _selectedDate.month && 
                        localStart.day == _selectedDate.day;
      
      if (!isSameDay) return false;
      
      if (_selectedCategoryId != "all") {
        if (schedule.classModel?.categoryId != _selectedCategoryId) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
                      : _buildMainContent(),
                ),
              ],
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: bgDark.withOpacity(0.95),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("GYM & CO.", style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 2),
                    const Text("Schedule", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
                  child: const Icon(Icons.search, color: Colors.white, size: 20),
                )
              ],
            ),
          ),
          // Date Strip
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _dateStrip.length,
              itemBuilder: (context, index) {
                final date = _dateStrip[index];
                final isSelected = date.year == _selectedDate.year && 
                                   date.month == _selectedDate.month && 
                                   date.day == _selectedDate.day;
                
                final dayStr = DateFormat('EEE').format(date);
                final dateStr = DateFormat('d').format(date);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? AppTheme.primary : Colors.white.withOpacity(0.05)),
                      boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 15)] : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dayStr, style: TextStyle(color: isSelected ? Colors.white.withOpacity(0.8) : textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                        Text(dateStr, style: TextStyle(color: isSelected ? Colors.white : textMuted, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Filter Chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildCategoryChip("all", "All Classes"),
                ..._categories.map((c) => _buildCategoryChip(c.id, c.name)).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String id, String name) {
    final isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? bgDark : Colors.white.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    final schedules = _filteredSchedules;
    
    if (schedules.isEmpty) {
      return Center(
        child: Text("No sessions available.", style: TextStyle(color: textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
      itemCount: schedules.length + 1, // +1 for the section label
      itemBuilder: (context, index) {
        if (index == 0) {
          final isToday = _selectedDate.day == DateTime.now().day;
          final title = isToday ? "Today's Sessions" : "${DateFormat('EEEE').format(_selectedDate)}'s Sessions";
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("${schedules.length} available", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }

        final schedule = schedules[index - 1];
        return _buildClassCard(schedule);
      },
    );
  }

  Widget _buildClassCard(ClassSchedule schedule) {
    final classData = schedule.classModel;
    final instructor = schedule.instructor;
    
    final startTime = DateFormat('HH:mm').format(schedule.startTime.toLocal());
    final duration = classData?.durationMinutes ?? 0;
    
    final bookedCount = schedule.bookedCount ?? 0;
    final availableSpots = schedule.capacity - bookedCount;
    final isFull = availableSpots <= 0;
    final isLimited = availableSpots > 0 && availableSpots <= 5;
    
    // Status specific styling
    final String statusText = isFull ? "Waitlist" : (isLimited ? "$availableSpots spots left" : "$availableSpots / ${schedule.capacity}");
    final Color statusColor = isFull ? textMuted : (isLimited ? Colors.orangeAccent : Colors.greenAccent);
    final IconData statusIcon = isFull ? Icons.block : (isLimited ? Icons.timelapse : Icons.circle);
    
    final String buttonText = isFull ? "Join Waitlist" : "Book";
    final Color buttonColor = isFull ? Colors.transparent : AppTheme.primary;
    final Color buttonTextColor = isFull ? Colors.white.withOpacity(0.8) : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ClassDetailScreen(scheduleId: schedule.id)),
        ).then((_) => _loadData()); // Refresh if they booked
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 140,
        decoration: BoxDecoration(
          color: cardDark.withOpacity(isFull ? 0.6 : 1.0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: isFull ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Stripe Background for Full classes
              if (isFull)
                Positioned.fill(
                  child: CustomPaint(painter: StripePainter()),
                ),
              Row(
                children: [
                  // Content Left
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(isFull ? 0.05 : 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _getCategoryName(classData?.categoryId).toUpperCase(),
                                      style: TextStyle(color: isFull ? textMuted : Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("$startTime • ${duration}m", style: TextStyle(color: isFull ? textMuted : AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(classData?.name ?? 'Clase', style: TextStyle(color: isFull ? Colors.white.withOpacity(0.8) : Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.person, color: textMuted, size: 14),
                                  const SizedBox(width: 4),
                                  Text("with ${instructor?.name ?? ''}", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isFull ? "STATUS" : "AVAILABILITY", style: TextStyle(color: textMuted, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(statusIcon, color: statusColor, size: 10),
                                      const SizedBox(width: 4),
                                      Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: buttonColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isFull ? Border.all(color: Colors.white.withOpacity(0.2)) : null,
                                  boxShadow: isFull ? [] : [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                child: Text(buttonText, style: TextStyle(color: buttonTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Image Right
                  Expanded(
                    flex: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (classData?.imageUrl != null)
                          ColorFiltered(
                            colorFilter: isFull 
                                ? const ColorFilter.matrix(<double>[
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0.2126, 0.7152, 0.0722, 0, 0,
                                    0,      0,      0,      0.5, 0,
                                  ]) 
                                : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                            child: Image.network(classData!.imageUrl!, fit: BoxFit.cover),
                          ),
                        // Gradient Overlay to blend with card
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [cardDark, cardDark.withOpacity(0.5), Colors.transparent],
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
        ),
      ),
    );
  }

  String _getCategoryName(String? categoryId) {
    if (categoryId == null) return "Class";
    try {
      return _categories.firstWhere((c) => c.id == categoryId).name;
    } catch (_) {
      return "Class";
    }
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 72 + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          color: bgDark.withOpacity(0.95),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(icon: Icons.home_filled, label: "Inicio", isSelected: false, onTap: () {
                     Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => const HomePage(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  }),
                  _buildNavItem(icon: Icons.search, label: "Explorar", isSelected: true, onTap: () {}),
                  _buildNavItem(icon: Icons.calendar_today, label: "Reservas", isSelected: false, onTap: () {
                     Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => const MyReservationsScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  }),
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
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required bool isSelected, required VoidCallback onTap}) {
    final color = isSelected ? AppTheme.primary : textMuted.withOpacity(0.6);
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
                color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.2), blurRadius: 10)] : [],
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

// Custom Painter for diagonal stripes
class StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    const spacing = 15.0;
    
    // Draw diagonal lines
    for (double i = -size.height; i < size.width; i += spacing) {
      path.moveTo(i, 0);
      path.lineTo(i + size.height, size.height);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
