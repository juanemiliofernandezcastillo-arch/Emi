import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../store.dart';
import '../models.dart';
import '../widgets/cyberpunk_charts.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    final history = store.history;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "WORKOUT HISTORY",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              Text(
                "${history.length} Workouts",
                style: const TextStyle(color: CyberTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Divider(color: CyberTheme.borderTranslucent, height: 24),

          if (history.isEmpty)
            Container(
              height: 300,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 48, color: CyberTheme.textSecondary),
                  SizedBox(height: 12),
                  Text("No completed workouts yet", style: TextStyle(color: CyberTheme.textSecondary)),
                ],
              ),
            ),

          ...history.map((session) => _buildHistoryCard(context, store, session)),
          
          const SizedBox(height: 80), // spacer for timer
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, WorkoutStore store, WorkoutSession session) {
    final dateStr = "${session.startTime.month}/${session.startTime.day}/${session.startTime.year}";
    final durationStr = _formatDuration(session.durationInSeconds);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          session.name.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white, letterSpacing: 0.5),
        ),
        subtitle: Text(
          "$dateStr • $durationStr • ${session.totalVolume.toStringAsFixed(0)} ${store.weightUnit}",
          style: const TextStyle(color: CyberTheme.cyberTeal, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: CyberTheme.textSecondary),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: CyberTheme.neonRose, size: 20),
                  SizedBox(width: 8),
                  Text("Delete log", style: TextStyle(color: CyberTheme.neonRose)),
                ],
              ),
            )
          ],
          onSelected: (val) {
            if (val == 'delete') {
              _confirmDelete(context, store, session);
            }
          },
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Detailed list of exercises and sets
          ...session.exercises.map((ex) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ex.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
                    ),
                    // Progress analysis shortcut
                    InkWell(
                      onTap: () => _showProgressChartDialog(context, store, ex.id, ex.name),
                      child: const Row(
                        children: [
                          Icon(Icons.show_chart_rounded, size: 16, color: CyberTheme.cyberTeal),
                          SizedBox(width: 4),
                          Text("Progress", style: TextStyle(fontSize: 11, color: CyberTheme.cyberTeal, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                // Sets rows
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: List.generate(ex.sets.length, (setIdx) {
                    final setLog = ex.sets[setIdx];
                    final rirStr = setLog.rir >= 0 ? " (RIR ${setLog.rir})" : "";
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: CyberTheme.inputBg.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CyberTheme.borderTranslucent),
                      ),
                      child: Text(
                        "Set ${setIdx + 1}: ${setLog.weight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}${store.weightUnit} x ${setLog.reps}$rirStr",
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    );
                  }),
                )
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return "0m";
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) {
      return "${h}h ${m}m";
    }
    return "${m}m";
  }

  void _confirmDelete(BuildContext context, WorkoutStore store, WorkoutSession session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("DELETE WORKOUT LOG?"),
        content: Text("Are you sure you want to delete '${session.name}' from your history? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              store.deleteWorkoutFromHistory(session.id);
              Navigator.pop(context);
            },
            child: const Text("DELETE", style: TextStyle(color: CyberTheme.neonRose)),
          ),
        ],
      ),
    );
  }

  void _showProgressChartDialog(BuildContext context, WorkoutStore store, String exerciseId, String exerciseName) {
    final progress = store.getExerciseProgress(exerciseId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CyberTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: CyberTheme.borderTranslucent),
        ),
        title: Text(
          "${exerciseName.toUpperCase()} 1RM PROGRESS",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VolumeLineChart(progressData: progress),
              const SizedBox(height: 12),
              const Text(
                "Estimated One-Rep Max trends computed using the Epley Formula.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: CyberTheme.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          )
        ],
      ),
    );
  }
}
