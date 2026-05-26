import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models.dart';
import '../services/classes_service.dart';
import '../services/bookings_service.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  List<ClassSchedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    _schedules = await ClassesService().getUpcomingSchedules();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Estudiantes y Check-in')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                final schedule = _schedules[index];
                return Card(
                  color: AppTheme.surface,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ExpansionTile(
                    title: Text(schedule.classModel?.name ?? 'Clase', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "${DateFormat('E, d MMM - HH:mm').format(schedule.startTime)} • ${schedule.bookedCount}/${schedule.capacity} lugares reservados",
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    children: [
                      _StudentListForSchedule(scheduleId: schedule.id),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _StudentListForSchedule extends StatefulWidget {
  final String scheduleId;
  const _StudentListForSchedule({required this.scheduleId});

  @override
  State<_StudentListForSchedule> createState() => _StudentListForScheduleState();
}

class _StudentListForScheduleState extends State<_StudentListForSchedule> {
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    _bookings = await BookingsService().getBookingsForSchedule(widget.scheduleId);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_bookings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No hay estudiantes reservados para esta clase.', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        final profile = booking.profile;
        final isWaitlist = booking.status == BookingStatus.waitlist;
        final isCancelled = booking.status == BookingStatus.cancelled;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.2),
            backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
            child: profile?.avatarUrl == null ? const Icon(Icons.person, color: AppTheme.primary) : null,
          ),
          title: Text(profile?.fullName ?? 'Usuario Desconocido', style: TextStyle(color: isCancelled ? Colors.white38 : Colors.white)),
          subtitle: Text(isCancelled ? 'Cancelado' : (isWaitlist ? 'Lista de Espera' : 'Confirmado'), 
            style: TextStyle(color: isCancelled ? Colors.redAccent : (isWaitlist ? Colors.amber : Colors.green))
          ),
          trailing: isCancelled ? null : Checkbox(
            value: booking.isPresent,
            activeColor: AppTheme.primary,
            onChanged: (val) async {
              if (val != null) {
                await BookingsService().markPresence(booking.id, val);
                _loadBookings(); // reload
              }
            },
          ),
        );
      },
    );
  }
}
