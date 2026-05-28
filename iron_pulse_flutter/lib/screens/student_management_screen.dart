import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import '../services/classes_service.dart';
import '../services/bookings_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final Color bgDark = const Color(0xFF121416);
  final Color surfaceDark = const Color(0xFF1A1D21);
  final Color primaryColor = const Color(0xFF17A1CF);
  final Color textMain = const Color(0xFFE0E4EB);
  final Color textMuted = const Color(0xFF7A8490);

  bool _isLoading = true;
  ClassSchedule? _currentSchedule;
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final nowStr = DateTime.now().toUtc().toIso8601String();
      // Fetch upcoming schedule
      final response = await Supabase.instance.client
          .from('class_schedules')
          .select('*, classes(*), profiles(*)')
          .gte('start_time', nowStr)
          .order('start_time', ascending: true)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        _currentSchedule = ClassSchedule.fromJson(response);
        _bookings = await BookingsService().getBookingsForSchedule(_currentSchedule!.id);
      }
    } catch (e) {
      print('Error loading schedule: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reloadBookings() async {
    if (_currentSchedule != null) {
      final updatedBookings = await BookingsService().getBookingsForSchedule(_currentSchedule!.id);
      if (mounted) {
        setState(() {
          _bookings = updatedBookings;
        });
      }
    }
  }

  Future<void> _togglePresence(Booking booking, bool isPresent) async {
    // Optimistic UI update by finding booking and assuming success temporarily
    // To keep it simple, we just call DB and reload, adding a small loading state isn't strictly necessary with fast DB
    final success = await BookingsService().markPresence(booking.id, isPresent);
    if (success) {
      await _reloadBookings();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar estado')),
        );
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
                  : _currentSchedule == null
                      ? const Center(
                          child: Text(
                            "No hay clases programadas.",
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _reloadBookings,
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
                              _buildStudentList(),
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
             const SnackBar(content: Text('Añadir estudiante manualmente (Próximamente)')),
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
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "EDIT ROSTER",
                  style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
              children: [
                const TextSpan(text: "Asistencia de\n"),
                TextSpan(text: "la Clase", style: TextStyle(color: primaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    int enrolled = _bookings.where((b) => b.status == BookingStatus.confirmed).length;
    int present = _bookings.where((b) => b.status == BookingStatus.confirmed && b.isPresent).length;
    int spotsLeft = _currentSchedule!.capacity - enrolled;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.group,
            iconColor: primaryColor,
            label: "Enrolled",
            value: enrolled.toString(),
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            icon: Icons.check_circle,
            iconColor: const Color(0xFF78CC33),
            label: "Present",
            value: present.toString(),
            highlight: true,
          ),
          const SizedBox(width: 16),
          _buildStatCard(
            icon: Icons.event_seat,
            iconColor: Colors.orange,
            label: "Spots Left",
            value: spotsLeft.toString(),
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
      width: 140,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: highlight ? [BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 20)] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
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
    final className = _currentSchedule?.classModel?.name ?? 'Clase';
    String dateStr = '';
    if (_currentSchedule != null) {
      dateStr = DateFormat('MMM d, yyyy').format(_currentSchedule!.startTime);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildFilterButton("CLASS", className, Icons.expand_more, hasDot: true),
          const SizedBox(width: 12),
          _buildFilterButton("DATE", dateStr, Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value, IconData icon, {bool hasDot = false}) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selector próximamente...')),
        );
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: surfaceDark,
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
            const SizedBox(width: 12),
            Icon(icon, color: textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    int checkedIn = _bookings.where((b) => b.status == BookingStatus.confirmed && b.isPresent).length;
    int enrolled = _bookings.where((b) => b.status == BookingStatus.confirmed).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "ROSTER LIST",
            style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "$checkedIn / $enrolled Checked In",
              style: TextStyle(color: textMuted, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _bookings.map((booking) => _buildStudentItem(booking)).toList(),
      ),
    );
  }

  Widget _buildStudentItem(Booking booking) {
    final profile = booking.profile;
    final name = profile?.fullName ?? 'Usuario';
    final fallbackText = "Usuario Registrado";
    final avatarUrl = profile?.avatarUrl;

    if (booking.status == BookingStatus.waitlist) {
      return _buildWaitlistCard(name, avatarUrl);
    }
    
    if (booking.status == BookingStatus.cancelled) {
      return _buildCancelledCard(name, avatarUrl);
    }

    final isPresent = booking.isPresent;
    final statusColor = isPresent ? const Color(0xFF78CC33) : textMuted;
    final statusText = isPresent ? "CONFIRMED" : "RESERVED";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                  border: Border.all(color: isPresent ? primaryColor : Colors.transparent, width: 2),
                  image: DecorationImage(
                    image: avatarUrl != null 
                      ? NetworkImage(avatarUrl) 
                      : const NetworkImage('https://ui-avatars.com/api/?name=U&background=1A1D21&color=fff'),
                    fit: BoxFit.cover,
                    colorFilter: isPresent ? null : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                  ),
                ),
                child: !isPresent ? Container(decoration: BoxDecoration(color: bgDark.withOpacity(0.4), shape: BoxShape.circle)) : null,
              ),
              if (isPresent)
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    decoration: BoxDecoration(color: bgDark, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(Icons.check_circle, color: Color(0xFF78CC33), size: 18),
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
                    color: isPresent ? textMain : textMain.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profile?.phone ?? fallbackText,
                  style: TextStyle(color: textMuted, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
          // Toggle
          Switch(
            value: isPresent,
            onChanged: (val) => _togglePresence(booking, val),
            activeColor: Colors.white,
            activeTrackColor: primaryColor,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF2A2F36),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitlistCard(String name, String? avatarUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
              image: DecorationImage(
                image: avatarUrl != null 
                  ? NetworkImage(avatarUrl) 
                  : const NetworkImage('https://ui-avatars.com/api/?name=W&background=1A1D21&color=fff'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(color: textMain, fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        border: Border.all(color: Colors.orange.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text("WAITLIST", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(
                  "Lista de espera",
                  style: TextStyle(color: textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: textMuted),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledCard(String name, String? avatarUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 2),
              image: DecorationImage(
                image: avatarUrl != null 
                  ? NetworkImage(avatarUrl) 
                  : const NetworkImage('https://ui-avatars.com/api/?name=C&background=1A1D21&color=fff'),
                fit: BoxFit.cover,
                colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              ),
            ),
            child: Container(decoration: BoxDecoration(color: bgDark.withOpacity(0.6), shape: BoxShape.circle)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: Colors.redAccent.withOpacity(0.5),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  "CANCELLED",
                  style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
          const Icon(Icons.block, color: Colors.redAccent, size: 20),
        ],
      ),
    );
  }
}
