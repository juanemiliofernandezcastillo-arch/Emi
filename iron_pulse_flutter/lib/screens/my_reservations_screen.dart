import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../app_theme.dart';
import '../models.dart';
import '../services/bookings_service.dart';
import '../services/profile_service.dart';
import '../home_page.dart';
import 'explore_classes_screen.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final Color bgDark = const Color(0xFF121416);
  final Color surfaceDark = const Color(0xFF1E2329);
  final Color cardDark = const Color(0xFF1A1D21);
  final Color textMuted = const Color(0xFF7A8490);
  final Color accentGreen = const Color(0xFF78CC33);
  final Color accentOrange = const Color(0xFFE67C19);

  bool _isLoading = true;
  List<Booking> _allBookings = [];
  Profile? _profile;

  // 0 for List, 1 for Calendar (Calendar view not fully implemented as requested, but we toggle state)
  int _viewMode = 0;
  // 0 for Upcoming, 1 for History
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _profile = await ProfileService().getCurrentProfile();
    if (_profile != null) {
      _allBookings = await BookingsService().getUserBookings(_profile!.id);
      // We only care about confirmed or waitlist. Cancelled bookings can be in History, or ignored.
      // Let's include everything for now and filter.
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleCancel(Booking booking) async {
    // Show Bottom Sheet Confirmation
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildCancelBottomSheet(booking),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await BookingsService().cancelBooking(booking.id);
      await _loadData();
    }
  }

  Widget _buildCancelBottomSheet(Booking booking) {
    final className = booking.schedule?.classModel?.name ?? 'Clase';
    
    return Container(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            decoration: BoxDecoration(
              color: surfaceDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  "Cancel Class?",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(color: textMuted, fontSize: 14),
                    children: [
                      const TextSpan(text: "Are you sure you want to cancel "),
                      TextSpan(text: className, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const TextSpan(text: "? This action cannot be undone."),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentOrange.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: accentOrange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Late Cancellation Policy:", style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            const Text(
                              "Canceling within 2 hours of class start time will incur a \$10 fee.",
                              style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text("Keep Class", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: const Text("Confirm Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                _buildTabs(),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
                      : _buildListContent(),
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: bgDark.withOpacity(0.95),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconButton(Icons.arrow_back, () {
                 Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation1, animation2) => const HomePage(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  );
              }),
              const Text(
                "My Reservations",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              Stack(
                children: [
                  _buildIconButton(Icons.notifications, () {}),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgDark, width: 2),
                      ),
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

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          // View Toggle
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewMode = 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _viewMode == 0 ? bgDark : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.format_list_bulleted, size: 18, color: _viewMode == 0 ? Colors.white : textMuted),
                          const SizedBox(width: 8),
                          Text(
                            "List",
                            style: TextStyle(
                              color: _viewMode == 0 ? Colors.white : textMuted,
                              fontWeight: _viewMode == 0 ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _viewMode = 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _viewMode == 1 ? bgDark : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month, size: 18, color: _viewMode == 1 ? Colors.white : textMuted),
                          const SizedBox(width: 8),
                          Text(
                            "Calendar",
                            style: TextStyle(
                              color: _viewMode == 1 ? Colors.white : textMuted,
                              fontWeight: _viewMode == 1 ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            "UPCOMING",
                            style: TextStyle(
                              color: _tabIndex == 0 ? AppTheme.primary : textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        if (_tabIndex == 0)
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 12)],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            "HISTORY",
                            style: TextStyle(
                              color: _tabIndex == 1 ? AppTheme.primary : textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        if (_tabIndex == 1)
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 12)],
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
    );
  }

  Widget _buildListContent() {
    final now = DateTime.now();
    
    // Filter bookings based on tab
    final filteredBookings = _allBookings.where((b) {
      if (b.status == BookingStatus.cancelled) {
         // Cancelled go to history
         return _tabIndex == 1;
      }
      if (b.schedule == null) return false;
      
      final isPast = b.schedule!.startTime.toLocal().isBefore(now);
      if (_tabIndex == 0) return !isPast; // Upcoming
      return isPast; // History
    }).toList();

    // Group by Date String
    final grouped = groupBy(filteredBookings, (Booking b) {
       if (b.schedule == null) return "Unknown Date";
       final date = b.schedule!.startTime.toLocal();
       
       if (date.year == now.year && date.month == now.month && date.day == now.day) {
         return "Today, ${DateFormat('d MMM').format(date)}";
       }
       return DateFormat('EEEE, d MMM').format(date);
    });

    if (grouped.isEmpty) {
      return Center(
        child: Text(
          _tabIndex == 0 ? "No upcoming classes." : "No class history.",
          style: TextStyle(color: textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final bookings = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                dateKey.toUpperCase(),
                style: TextStyle(
                  color: textMuted.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            ...bookings.map((b) => _buildBookingCard(b)).toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    if (booking.schedule == null) return const SizedBox();

    final schedule = booking.schedule!;
    final classData = schedule.classModel;
    final instructor = schedule.instructor;
    
    final startTime = DateFormat('HH:mm').format(schedule.startTime.toLocal());
    final duration = classData?.durationMinutes ?? 0;
    
    final isConfirmed = booking.status == BookingStatus.confirmed;
    final isWaitlist = booking.status == BookingStatus.waitlist;
    final isCancelled = booking.status == BookingStatus.cancelled;
    
    Color accentColor = isCancelled ? Colors.redAccent : (isConfirmed ? accentGreen : accentOrange);
    String statusText = isCancelled ? "Cancelled" : (isConfirmed ? "Confirmed" : "Waitlist");
    IconData statusIcon = isCancelled ? Icons.cancel : (isConfirmed ? Icons.check_circle : Icons.hourglass_empty);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Left Accent Bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: accentColor),
            ),
            Row(
              children: [
                // Left Time Block
                Container(
                  width: 80,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2429),
                    border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Start", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(startTime, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      Container(
                        width: 1,
                        height: 32,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white.withOpacity(0.2), Colors.transparent],
                          ),
                        ),
                      ),
                      Text("${duration}m", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                // Right Content Block
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                classData?.name ?? 'Clase',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.1),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: accentColor.withOpacity(0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isConfirmed)
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle))
                                  else
                                    Icon(statusIcon, color: accentColor, size: 10),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText.toUpperCase(),
                                    style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Details
                        Row(
                          children: [
                            Icon(Icons.person, color: textMuted, size: 16),
                            const SizedBox(width: 8),
                            Text("Instructor: ", style: TextStyle(color: textMuted, fontSize: 14)),
                            Text(instructor?.name ?? 'No asignado', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: textMuted, size: 16),
                            const SizedBox(width: 8),
                            Text(schedule.locationName ?? 'Main Studio', style: TextStyle(color: textMuted, fontSize: 14)),
                          ],
                        ),
                        
                        if (_tabIndex == 0 && !isCancelled) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _handleCancel(booking),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                isWaitlist ? "LEAVE WAITLIST" : "CANCEL RESERVATION",
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                  _buildNavItem(icon: Icons.search, label: "Explorar", isSelected: false, onTap: () {
                     Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) => const ExploreClassesScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  }),
                  _buildNavItem(icon: Icons.calendar_today, label: "Reservas", isSelected: true, onTap: () {}),
                  _buildNavItem(icon: Icons.person_outline, label: "Perfil", isSelected: false, onTap: () {}),
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
