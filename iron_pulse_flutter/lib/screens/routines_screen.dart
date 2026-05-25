import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../store.dart';
import '../models.dart';

class RoutinesScreen extends StatelessWidget {
  final Function(int) onTabChange;

  const RoutinesScreen({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    final routines = store.routines;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRoutineSheet(context, store),
        backgroundColor: CyberTheme.cyberTeal,
        foregroundColor: CyberTheme.background,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ROUTINES & TEMPLATES",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
              Text(
                "${routines.length} Available",
                style: const TextStyle(color: CyberTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Divider(color: CyberTheme.borderTranslucent, height: 24),
          
          if (routines.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const Text("No routines found. Create one with the '+' button!", style: TextStyle(color: CyberTheme.textSecondary)),
            ),

          ...routines.map((routine) => _buildRoutineCard(context, store, routine)),
          
          const SizedBox(height: 80), // spacer for timer
        ],
      ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, WorkoutStore store, WorkoutRoutine routine) {
    // Get details of exercises
    final List<String> exerciseNames = routine.exerciseIds
        .map((id) => store.getExerciseById(id)?.name ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          routine.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        subtitle: Text(
          routine.description.isNotEmpty ? routine.description : "No description",
          style: const TextStyle(color: CyberTheme.textSecondary, fontSize: 12),
        ),
        shape: const Border(), // remove default border line on expansion
        childrenPadding: const EdgeInsets.all(16),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: CyberTheme.textSecondary),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: CyberTheme.neonRose, size: 20),
                  SizedBox(width: 8),
                  Text("Delete template", style: TextStyle(color: CyberTheme.neonRose)),
                ],
              ),
            )
          ],
          onSelected: (val) {
            if (val == 'delete') {
              store.deleteRoutine(routine.id);
            }
          },
        ),
        children: [
          // Exercise names preview
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("EXERCISES:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CyberTheme.cyberTeal, letterSpacing: 1.0)),
                const SizedBox(height: 6),
                ...exerciseNames.map((name) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, size: 16, color: CyberTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(name, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Action button to start workout
          ElevatedButton(
            onPressed: () {
              store.startWorkout(routine.name, exerciseIds: routine.exerciseIds);
              onTabChange(1); // Switch to active workout tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: CyberTheme.cyberTeal,
              minimumSize: const Size(double.infinity, 44),
            ),
            child: const Text(
              "START WORKOUT FROM TEMPLATE",
              style: TextStyle(color: CyberTheme.background, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateRoutineSheet(BuildContext context, WorkoutStore store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CyberTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.6,
          expand: false,
          builder: (context, scrollController) {
            return CreateRoutineSheet(store: store, scrollController: scrollController);
          },
        );
      },
    );
  }
}

// Custom Routine Builder modal helper
class CreateRoutineSheet extends StatefulWidget {
  final WorkoutStore store;
  final ScrollController scrollController;

  const CreateRoutineSheet({super.key, required this.store, required this.scrollController});

  @override
  State<CreateRoutineSheet> createState() => _CreateRoutineSheetState();
}

class _CreateRoutineSheetState extends State<CreateRoutineSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<String> _selectedExerciseIds = [];
  String _searchQuery = "";

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = widget.store.allExercises.where((e) {
      return e.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CyberTheme.borderTranslucent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "CREATE CUSTOM ROUTINE",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
            ),
            const SizedBox(height: 16),
            
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Routine Name",
                hintText: "e.g., Upper Body Focus",
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Please enter a name";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Description Field
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: "Description (Optional)",
                hintText: "e.g., Alternate heavy sets with higher reps",
              ),
            ),
            const SizedBox(height: 16),

            // Selector Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("SELECT EXERCISES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CyberTheme.cyberTeal)),
                Text("${_selectedExerciseIds.length} Selected", style: const TextStyle(fontSize: 12, color: CyberTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),

            // Search Bar
            TextField(
              decoration: const InputDecoration(
                hintText: "Filter exercises...",
                prefixIcon: Icon(Icons.filter_list, size: 18),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
            const SizedBox(height: 8),

            // List of exercises to check
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: filteredExercises.length,
                itemBuilder: (context, index) {
                  final ex = filteredExercises[index];
                  final isChecked = _selectedExerciseIds.contains(ex.id);

                  return CheckboxListTile(
                    title: Text(ex.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text("${ex.muscleGroup} • ${ex.equipment}", style: const TextStyle(fontSize: 11, color: CyberTheme.textSecondary)),
                    value: isChecked,
                    activeColor: CyberTheme.cyberTeal,
                    checkColor: CyberTheme.background,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedExerciseIds.add(ex.id);
                        } else {
                          _selectedExerciseIds.remove(ex.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),

            const Divider(color: CyberTheme.borderTranslucent),
            const SizedBox(height: 8),

            // Save actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCEL"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_selectedExerciseIds.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please select at least one exercise")),
                          );
                          return;
                        }
                        widget.store.addRoutine(
                          _nameController.text.trim(),
                          _descController.text.trim(),
                          _selectedExerciseIds,
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.cyberTeal),
                    child: const Text("SAVE TEMPLATE", style: TextStyle(color: CyberTheme.background, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
