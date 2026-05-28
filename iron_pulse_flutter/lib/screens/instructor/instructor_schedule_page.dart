import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_theme.dart';
import '../../models.dart';
import '../../services/classes_service.dart';
import 'class_attendance_page.dart';

class InstructorSchedulePage extends StatefulWidget {
  const InstructorSchedulePage({super.key});

  @override
  State<InstructorSchedulePage> createState() => _InstructorSchedulePageState();
}

class _InstructorSchedulePageState extends State<InstructorSchedulePage> {
  List<ClassSchedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final schedules = await ClassesService().getInstructorSchedules(user.id);
      if (mounted) {
        setState(() {
          _schedules = schedules;
          _isLoading = false;
        });
      }
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
          "Mis Clases",
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadSchedules,
              color: AppTheme.primary,
              child: _schedules.isEmpty
                  ? Center(
                      child: Text(
                        "No tienes clases programadas próximamente.",
                        style: GoogleFonts.spaceGrotesk(color: AppTheme.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _schedules.length,
                      itemBuilder: (context, index) {
                        final schedule = _schedules[index];
                        return _buildScheduleCard(schedule);
                      },
                    ),
            ),
    );
  }

  Widget _buildScheduleCard(ClassSchedule schedule) {
    final startTime = DateFormat('dd MMM yyyy, HH:mm', 'es_ES').format(schedule.startTime);
    final className = schedule.classModel?.name ?? 'Clase Desconocida';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClassAttendancePage(schedule: schedule),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.borderTranslucent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    className,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    startTime,
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
