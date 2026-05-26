import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import '../store.dart';
import '../widgets/cyberpunk_charts.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int) onTabChange;

  const DashboardScreen({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    final user = Supabase.instance.client.auth.currentUser;
    final String fullName = user?.userMetadata?['full_name'] as String? ?? '';
    final String firstName = fullName.isNotEmpty ? fullName.split(' ').first : 'Athlete';

    // Calculate quick stats
    final totalWorkouts = store.history.length;
    final double totalVolume = store.history.fold(0.0, (sum, session) => sum + session.totalVolume);
    final String volumeDisplay = totalVolume >= 1000 
        ? "${(totalVolume / 1000).toStringAsFixed(1)}k" 
        : totalVolume.toStringAsFixed(0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cyber Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: CyberTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: CyberTheme.neonGlow(color: CyberTheme.neonRose, opacity: 0.25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PULSE DASHBOARD — ¡HOLA, ${firstName.toUpperCase()}! 🔥",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "DESATA TU PODER",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    store.startWorkout("Quick Start");
                    onTabChange(1); // Switch to Active Log tab
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: CyberTheme.neonRose,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 20),
                      SizedBox(width: 4),
                      Text("INICIAR ENTRENAMIENTO VACÍO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Quick Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: "ENTRENAMIENTOS TOTALES",
                  value: "$totalWorkouts",
                  icon: Icons.fitness_center_rounded,
                  accentColor: CyberTheme.cyberTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: "VOLUMEN LEVANTADO",
                  value: "$volumeDisplay ${store.weightUnit}",
                  icon: Icons.flash_on_rounded,
                  accentColor: CyberTheme.electricAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Consistency Heatmap
          ConsistencyGrid(data: store.getWeeklyConsistency()),
          const SizedBox(height: 20),

          // Muscle Group Radar Analysis
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Distribución de Volumen",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Carga total de entrenamiento por grupo muscular",
                    style: TextStyle(color: CyberTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  MuscleRadarChart(data: store.getVolumeByMuscleGroup()),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 80), // bottom spacing for overlay timer
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.2), width: 1),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: CyberTheme.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
