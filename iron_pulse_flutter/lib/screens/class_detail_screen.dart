import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models.dart';
import '../services/classes_service.dart';
import '../services/bookings_service.dart';
import '../services/profile_service.dart';

class ClassDetailScreen extends StatefulWidget {
  final String scheduleId;

  const ClassDetailScreen({super.key, required this.scheduleId});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  ClassSchedule? _schedule;
  Booking? _userBooking;
  Profile? _profile;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    _profile = await ProfileService().getCurrentProfile();
    _schedule = await ClassesService().getScheduleDetails(widget.scheduleId);
    
    if (_profile != null && _schedule != null) {
      _userBooking = await BookingsService().getUserBookingForSchedule(_profile!.id, _schedule!.id);
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleAction() async {
    if (_profile == null || _schedule == null) return;

    setState(() => _isProcessing = true);
    try {
      if (_userBooking != null && _userBooking!.status != BookingStatus.cancelled) {
        // Cancelar reserva
        await BookingsService().cancelBooking(_userBooking!.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Cancelled')));
      } else {
        // Reservar
        await BookingsService().reserveClass(_profile!.id, _schedule!);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class Reserved successfully!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    
    await _loadData();
    setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_schedule == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Details')),
        body: const Center(child: Text('Class not found', style: TextStyle(color: Colors.white))),
      );
    }

    final isBooked = _userBooking != null && _userBooking!.status != BookingStatus.cancelled;
    final isWaitlist = _userBooking?.status == BookingStatus.waitlist;
    final availableSpots = _schedule!.availableSpots;
    
    final dayFormat = DateFormat('EEEE, MMMM d');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_schedule!.classModel?.imageUrl != null)
                    Image.network(_schedule!.classModel!.imageUrl!, fit: BoxFit.cover)
                  else
                    Container(color: AppTheme.surface),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTheme.background,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _schedule!.classModel?.name ?? 'Class',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        dayFormat.format(_schedule!.startTime),
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "${timeFormat.format(_schedule!.startTime)} - ${timeFormat.format(_schedule!.endTime)} (${_schedule!.classModel?.durationMinutes ?? 60}m)",
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _schedule!.instructor?.name ?? 'No Instructor',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.group, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        availableSpots > 0 ? "$availableSpots spots left" : "Class Full",
                        style: TextStyle(color: availableSpots > 0 ? Colors.green : Colors.redAccent, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_schedule!.classModel?.description != null) ...[
                    const Text("About", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      _schedule!.classModel!.description!,
                      style: const TextStyle(color: Colors.white70, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: const Border(top: BorderSide(color: Colors.white10)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBooked ? Colors.redAccent : AppTheme.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isProcessing ? null : _handleAction,
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isBooked
                        ? "Cancel Booking"
                        : (availableSpots > 0 ? "Reserve Spot" : "Join Waitlist"),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
