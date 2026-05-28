import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app_theme.dart';
import '../../services/bookings_service.dart';
import 'package:google_fonts/google_fonts.dart';

class InstructorDashboardPage extends StatefulWidget {
  const InstructorDashboardPage({super.key});

  @override
  State<InstructorDashboardPage> createState() => _InstructorDashboardPageState();
}

class _InstructorDashboardPageState extends State<InstructorDashboardPage> {
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final metrics = await BookingsService().getInstructorDashboardMetrics(user.id);
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          "Dashboard Instructor",
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMetrics,
        color: AppTheme.primary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMetricCard(
              "Clases Hoy",
              _metrics['scheduled_classes_today']?.toString() ?? "0",
              Icons.fitness_center,
              AppTheme.primary,
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              "Estudiantes Hoy",
              _metrics['total_students_today']?.toString() ?? "0",
              Icons.group,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              "Ocupación Promedio",
              "${(_metrics['occupancy_rate'] as double? ?? 0.0).toStringAsFixed(1)}%",
              Icons.percent,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderTranslucent),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
