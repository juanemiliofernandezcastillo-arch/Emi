import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
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
  Category? _category;
  bool _isLoading = true;
  bool _isProcessing = false;

  final Color bgDark = const Color(0xFF121417);
  final Color surfaceDark = const Color(0xFF1A1D21);
  final Color textMuted = const Color(0xFF7A8490);
  final Color accentOrange = const Color(0xFFE67C19);

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
      final categories = await ClassesService().getCategories();
      try {
        _category = categories.firstWhere((c) => c.id == _schedule!.classModel?.categoryId);
      } catch (_) {}
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleReserve() async {
    if (_profile == null || _schedule == null) return;

    setState(() => _isProcessing = true);
    try {
      if (_userBooking != null && _userBooking!.status != BookingStatus.cancelled) {
        // Cancelar reserva
        await BookingsService().cancelBooking(_userBooking!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reserva Cancelada')));
        }
      } else {
        // Reservar
        await BookingsService().reserveClass(_profile!.id, _schedule!);
        if (mounted) {
          _showSuccessModal();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    
    await _loadData();
    setState(() => _isProcessing = false);
  }

  void _showSuccessModal() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      pageBuilder: (context, anim1, anim2) {
        return _SuccessModal(
          schedule: _schedule!,
          onDone: () => Navigator.of(context).pop(),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(
                parent: anim1,
                curve: Curves.easeOutBack,
              )),
              child: child,
            ),
          ),
        );
      },
    );
  }

  int _calculateCalories(ClassIntensity intensity, int durationMinutes) {
    switch (intensity) {
      case ClassIntensity.high:
        return durationMinutes * 10;
      case ClassIntensity.medium:
        return (durationMinutes * 7.5).round();
      case ClassIntensity.low:
        return durationMinutes * 5;
    }
  }

  String _getIntensityString(ClassIntensity intensity) {
    switch (intensity) {
      case ClassIntensity.high:
        return 'High';
      case ClassIntensity.medium:
        return 'Medium';
      case ClassIntensity.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgDark,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_schedule == null) {
      return Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(title: const Text('Detalles')),
        body: const Center(child: Text('Clase no encontrada', style: TextStyle(color: Colors.white))),
      );
    }

    final classData = _schedule!.classModel!;
    final isBooked = _userBooking != null && _userBooking!.status != BookingStatus.cancelled;
    final isWaitlist = _userBooking?.status == BookingStatus.waitlist;
    final availableSpots = _schedule!.availableSpots;
    final isFull = availableSpots <= 0;
    
    final calories = _calculateCalories(classData.intensity, classData.durationMinutes);
    final intensityStr = _getIntensityString(classData.intensity);
    
    final dayFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Background Image (Top 45%)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: _buildHeroBackground(classData.imageUrl),
          ),

          // Custom Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGlassyIconButton(
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        _buildGlassyIconButton(icon: Icons.ios_share),
                        const SizedBox(width: 12),
                        _buildGlassyIconButton(
                          icon: Icons.favorite,
                          iconColor: AppTheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.45 - 120, // Start just above bottom of image
                bottom: 120, // Space for sticky bottom bar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Titles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            (_category?.name ?? intensityStr).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          classData.name,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Instructor Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
                                image: DecorationImage(
                                  image: NetworkImage(_schedule!.instructor?.avatarUrl ?? 'https://via.placeholder.com/150'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "INSTRUCTOR",
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  _schedule!.instructor?.name ?? 'No asignado',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "View Profile",
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bento Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Date & Time Full Width Card
                        _buildBentoCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.calendar_today, color: textMuted, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Date & Time", style: TextStyle(color: textMuted, fontSize: 12)),
                                      Text(
                                        "${dayFormat.format(_schedule!.startTime)} • ${timeFormat.format(_schedule!.startTime)}",
                                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 32, color: Colors.white.withOpacity(0.1)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("Duration", style: TextStyle(color: textMuted, fontSize: 12)),
                                  Text(
                                    "${classData.durationMinutes} min",
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Split Cards
                        Row(
                          children: [
                            // Availability Card
                            Expanded(
                              child: _buildBentoCard(
                                isGroup: true,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: -8,
                                      right: -8,
                                      child: Icon(Icons.local_fire_department, color: Colors.white.withOpacity(0.05), size: 48),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Availability", style: TextStyle(color: textMuted, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(
                                          isFull ? "Full" : "$availableSpots Spots",
                                          style: TextStyle(
                                            color: isFull ? Colors.redAccent : accentOrange,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (!isFull && availableSpots <= 5)
                                          Row(
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(color: accentOrange, shape: BoxShape.circle),
                                              ),
                                              const SizedBox(width: 4),
                                              Text("Filling fast", style: TextStyle(color: textMuted, fontSize: 10)),
                                            ],
                                          )
                                        else if (isFull)
                                          Text("Waitlist available", style: TextStyle(color: textMuted, fontSize: 10))
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Intensity Card
                            Expanded(
                              child: _buildBentoCard(
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: -8,
                                      right: -8,
                                      child: Icon(Icons.bolt, color: Colors.white.withOpacity(0.05), size: 48),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Intensity", style: TextStyle(color: textMuted, fontSize: 12)),
                                        const SizedBox(height: 4),
                                        Text(
                                          intensityStr,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text("~$calories kcal", style: TextStyle(color: textMuted, fontSize: 10)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "About the Class",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          classData.description ?? "No hay descripción disponible.",
                          style: TextStyle(color: textMuted, fontSize: 14, height: 1.6),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text("Read more", style: TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            Icon(Icons.expand_more, color: AppTheme.primary, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Location
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: bgDark,
                              borderRadius: BorderRadius.circular(12),
                              image: const DecorationImage(
                                image: NetworkImage('https://placeholder.pics/svg/300'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _schedule!.locationName ?? 'Sede Principal',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "123 Fitness Blvd, Downtown",
                                  style: TextStyle(color: textMuted, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    bgDark,
                    bgDark.withOpacity(0.9),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Total Price", style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                      Text(
                        "\$${classData.basePrice.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: GestureDetector(
                      onTap: _isProcessing ? null : _handleReserve,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: isBooked ? Colors.redAccent : AppTheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isBooked ? [] : [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isProcessing)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            else ...[
                              Text(
                                isBooked ? "Cancelar" : (isFull ? "Waitlist" : "Reserve Now"),
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              if (!isBooked) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ]
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBackground(String? imageUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null)
          Image.network(imageUrl, fit: BoxFit.cover)
        else
          Container(color: surfaceDark),
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                bgDark,
                bgDark.withOpacity(0.6),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassyIconButton({required IconData icon, Color iconColor = Colors.white, VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoCard({required Widget child, bool isGroup = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }
}

class _SuccessModal extends StatefulWidget {
  final ClassSchedule schedule;
  final VoidCallback onDone;

  const _SuccessModal({required this.schedule, required this.onDone});

  @override
  State<_SuccessModal> createState() => _SuccessModalState();
}

class _SuccessModalState extends State<_SuccessModal> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Auto-close after 3 seconds
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayFormat = DateFormat('MMM d');
    final className = widget.schedule.classModel?.name ?? 'Clase';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D21),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                offset: const Offset(0, 20),
              )
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Glow effect
              Positioned(
                top: -50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              // Close button
              Positioned(
                top: -16,
                right: -16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF7A8490)),
                  onPressed: widget.onDone,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppTheme.primary,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Class Booked!",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You're all set for $className on ${dayFormat.format(widget.schedule.startTime)}.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF7A8490), fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  // Add to Calendar Button
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.calendar_month, color: Color(0xFF121417), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Add to Calendar",
                          style: TextStyle(color: Color(0xFF121417), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Done Button
                  GestureDetector(
                    onTap: widget.onDone,
                    child: Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Done",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
}
