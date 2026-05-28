import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../models.dart';
import '../../services/bookings_service.dart';

class ClassAttendancePage extends StatefulWidget {
  final ClassSchedule schedule;

  const ClassAttendancePage({super.key, required this.schedule});

  @override
  State<ClassAttendancePage> createState() => _ClassAttendancePageState();
}

class _ClassAttendancePageState extends State<ClassAttendancePage> {
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final bookings = await BookingsService().getBookingsForSchedule(widget.schedule.id);
    if (mounted) {
      setState(() {
        _bookings = bookings.where((b) => b.status == BookingStatus.confirmed).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePresence(Booking booking, bool isPresent) async {
    final success = await BookingsService().markPresence(booking.id, isPresent);
    if (success && mounted) {
      setState(() {
        final index = _bookings.indexWhere((b) => b.id == booking.id);
        if (index != -1) {
          _bookings[index] = Booking(
            id: booking.id,
            userId: booking.userId,
            scheduleId: booking.scheduleId,
            status: booking.status,
            isPresent: isPresent,
            createdAt: booking.createdAt,
            profile: booking.profile,
            schedule: booking.schedule,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          "Asistencia",
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _bookings.isEmpty
              ? Center(
                  child: Text(
                    "No hay estudiantes confirmados.",
                    style: GoogleFonts.spaceGrotesk(color: AppTheme.textMuted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final studentName = booking.profile?.fullName ?? 'Sin Nombre';
                    final avatar = booking.profile?.avatarUrl;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderTranslucent),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primary.withOpacity(0.2),
                            backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                            child: avatar == null
                                ? const Icon(Icons.person, color: AppTheme.primary)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              studentName,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Switch(
                            value: booking.isPresent,
                            activeColor: AppTheme.primary,
                            onChanged: (val) => _togglePresence(booking, val),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
