import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../store.dart';
import '../models.dart';
import '../db.dart';

class ActiveLogScreen extends StatelessWidget {
  const ActiveLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    final active = store.activeWorkout;

    if (active == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CyberTheme.neonRose.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(color: CyberTheme.neonRose.withOpacity(0.15), width: 2),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: CyberTheme.neonRose,
                  size: 64,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "NO ACTIVE WORKOUT",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Start an empty workout or select a template from the Routines tab to begin tracking.",
                textAlign: TextAlign.center,
                style: TextStyle(color: CyberTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => store.startWorkout("Quick Start"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: CyberTheme.primaryGradient,
                  ),
                  child: const Text(
                    "START QUICK WORKOUT",
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final durationMin = (store.workoutElapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final durationSec = (store.workoutElapsedSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, color: CyberTheme.cyberTeal, size: 18),
            const SizedBox(width: 6),
            Text(
              "$durationMin:$durationSec",
              style: const TextStyle(
                fontFamily: 'monospace',
                color: CyberTheme.cyberTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: CyberTheme.cyberTeal),
            tooltip: "Add Exercise",
            onPressed: () => _showAddExerciseSheet(context, store),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Workout Title & Main Actions
          Row(
            children: [
              Expanded(
                child: Text(
                  active.name.toUpperCase(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
              ),
              TextButton(
                onPressed: () => _confirmDiscardWorkout(context, store),
                child: const Text("DISCARD", style: TextStyle(color: CyberTheme.neonRose)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => store.finishWorkout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CyberTheme.cyberTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text(
                  "FINISH",
                  style: TextStyle(color: CyberTheme.background, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: CyberTheme.borderTranslucent, height: 24),

          // Logged Exercises List
          if (active.exercises.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const Text(
                "Tap '+' at the top to add your first exercise!",
                style: TextStyle(color: CyberTheme.textSecondary),
              ),
            ),

          ...active.exercises.map((ex) => _buildExerciseCard(context, store, ex)),
          
          const SizedBox(height: 100), // Spacing for floating rest timer
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, WorkoutStore store, LoggedExercise ex) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    ex.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: CyberTheme.textSecondary),

                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: CyberTheme.neonRose, size: 20),
                          SizedBox(width: 8),
                          Text("Remove exercise", style: TextStyle(color: CyberTheme.neonRose)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'delete') {
                      store.removeExerciseFromActiveWorkout(ex.id);
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 12),

            // Table headers
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                children: [
                  SizedBox(width: 32, child: Text("SET", style: TextStyle(fontSize: 10, color: CyberTheme.textSecondary, fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Center(child: Text("KG", style: TextStyle(fontSize: 10, color: CyberTheme.textSecondary, fontWeight: FontWeight.bold)))),
                  SizedBox(width: 8),
                  Expanded(flex: 3, child: Center(child: Text("REPS", style: TextStyle(fontSize: 10, color: CyberTheme.textSecondary, fontWeight: FontWeight.bold)))),
                  SizedBox(width: 8),
                  Expanded(flex: 2, child: Center(child: Text("RIR", style: TextStyle(fontSize: 10, color: CyberTheme.textSecondary, fontWeight: FontWeight.bold)))),
                  SizedBox(width: 12),
                  SizedBox(width: 40, child: Center(child: Text("DONE", style: TextStyle(fontSize: 10, color: CyberTheme.textSecondary, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Set inputs
            ...List.generate(ex.sets.length, (index) {
              return ActiveSetRow(
                key: ValueKey("${ex.id}_set_$index"),
                exerciseId: ex.id,
                setIndex: index,
                setLog: ex.sets[index],
                onDelete: () => store.removeSetFromExercise(ex.id, index),
              );
            }),
            
            const SizedBox(height: 12),

            // Add Set Action
            OutlinedButton(
              onPressed: () => store.addSetToExercise(ex.id),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: CyberTheme.borderTranslucent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(double.infinity, 38),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 16, color: CyberTheme.cyberTeal),
                  SizedBox(width: 4),
                  Text("ADD SET", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CyberTheme.cyberTeal)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showAddExerciseSheet(BuildContext context, WorkoutStore store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CyberTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return AddExerciseSelector(store: store, scrollController: scrollController);
          },
        );
      },
    );
  }

  void _confirmDiscardWorkout(BuildContext context, WorkoutStore store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("DISCARD WORKOUT?"),
        content: const Text("Are you sure you want to discard this workout? All progress logged in this session will be lost."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () {
              store.discardWorkout();
              Navigator.pop(context);
            },
            child: const Text("DISCARD", style: TextStyle(color: CyberTheme.neonRose)),
          ),
        ],
      ),
    );
  }
}

// Stateful cell row for butter-smooth typing inputs
class ActiveSetRow extends StatefulWidget {
  final String exerciseId;
  final int setIndex;
  final SetLog setLog;
  final VoidCallback onDelete;

  const ActiveSetRow({
    super.key,
    required this.exerciseId,
    required this.setIndex,
    required this.setLog,
    required this.onDelete,
  });

  @override
  State<ActiveSetRow> createState() => _ActiveSetRowState();
}

class _ActiveSetRowState extends State<ActiveSetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.setLog.weight > 0 ? widget.setLog.weight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') : '',
    );
    _repsController = TextEditingController(
      text: widget.setLog.reps > 0 ? widget.setLog.reps.toString() : '',
    );
  }

  @override
  void didUpdateWidget(covariant ActiveSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with outside state only when typing is not active and inputs differ
    if (!widget.setLog.isCompleted) return;
    
    final currentWeight = double.tryParse(_weightController.text) ?? 0.0;
    if (currentWeight != widget.setLog.weight) {
      _weightController.text = widget.setLog.weight > 0 ? widget.setLog.weight.toString() : '';
    }

    final currentReps = int.tryParse(_repsController.text) ?? 0;
    if (currentReps != widget.setLog.reps) {
      _repsController.text = widget.setLog.reps > 0 ? widget.setLog.reps.toString() : '';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _triggerUpdate(BuildContext context, {bool? completed, int? rirValue}) {
    final store = Provider.of<WorkoutStore>(context, listen: false);
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    
    store.updateSet(
      widget.exerciseId,
      widget.setIndex,
      widget.setLog.copyWith(
        weight: weight,
        reps: reps,
        rir: rirValue ?? widget.setLog.rir,
        isCompleted: completed ?? widget.setLog.isCompleted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.setLog.isCompleted ? CyberTheme.cyberTeal : Colors.white;

    return Dismissible(
      key: widget.key!,
      direction: DismissDirection.endToStart,
      background: Container(
        color: CyberTheme.neonRose.withOpacity(0.2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete_sweep_rounded, color: CyberTheme.neonRose),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            // Set Indicator Label
            SizedBox(
              width: 32,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: widget.setLog.isCompleted 
                    ? CyberTheme.cyberTeal.withOpacity(0.1) 
                    : CyberTheme.borderTranslucent,
                child: Text(
                  "${widget.setIndex + 1}",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.setLog.isCompleted ? CyberTheme.cyberTeal : Colors.white60,
                  ),
                ),
              ),
            ),
            
            // Weight input
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: activeColor, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    hintText: "0.0",
                  ),
                  onChanged: (_) => _triggerUpdate(context),
                  enabled: !widget.setLog.isCompleted,
                ),
              ),
            ),

            // Reps input
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: activeColor, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    hintText: "0",
                  ),
                  onChanged: (_) => _triggerUpdate(context),
                  enabled: !widget.setLog.isCompleted,
                ),
              ),
            ),

            // RIR dropdown
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: CyberTheme.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CyberTheme.borderTranslucent),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: widget.setLog.rir,
                    dropdownColor: CyberTheme.surface,
                    style: TextStyle(fontSize: 12, color: activeColor, fontWeight: FontWeight.bold),
                    alignment: Alignment.center,
                    items: const [
                      DropdownMenuItem(value: -1, child: Text("-")),
                      DropdownMenuItem(value: 0, child: Text("0")),
                      DropdownMenuItem(value: 1, child: Text("1")),
                      DropdownMenuItem(value: 2, child: Text("2")),
                      DropdownMenuItem(value: 3, child: Text("3")),
                      DropdownMenuItem(value: 4, child: Text("4+")),
                    ],
                    onChanged: widget.setLog.isCompleted 
                        ? null 
                        : (val) => _triggerUpdate(context, rirValue: val),
                  ),
                ),
              ),
            ),

            // Complete checkbox
            const SizedBox(width: 12),
            SizedBox(
              width: 40,
              child: Checkbox(
                value: widget.setLog.isCompleted,
                activeColor: CyberTheme.cyberTeal,
                checkColor: CyberTheme.background,
                side: BorderSide(
                  color: widget.setLog.isCompleted ? CyberTheme.cyberTeal : CyberTheme.textSecondary,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) {
                  if (val != null) {
                    _triggerUpdate(context, completed: val);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Exercise search & selection modal sheet
class AddExerciseSelector extends StatefulWidget {
  final WorkoutStore store;
  final ScrollController scrollController;

  const AddExerciseSelector({super.key, required this.store, required this.scrollController});

  @override
  State<AddExerciseSelector> createState() => _AddExerciseSelectorState();
}

class _AddExerciseSelectorState extends State<AddExerciseSelector> {
  String _searchQuery = "";
  String _selectedMuscle = "All";

  @override
  Widget build(BuildContext context) {
    final list = widget.store.allExercises.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMuscle = _selectedMuscle == "All" || e.muscleGroup == _selectedMuscle;
      return matchesSearch && matchesMuscle;
    }).toList();

    final muscles = ["All", ...muscleGroups];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        children: [
          // Grab handle
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
            "ADD EXERCISE TO WORKOUT",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
          ),
          const SizedBox(height: 16),
          
          // Search box
          TextField(
            decoration: const InputDecoration(
              hintText: "Search exercises...",
              prefixIcon: Icon(Icons.search, color: CyberTheme.textSecondary),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 10),

          // Muscle Chips Filter
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: muscles.length,
              itemBuilder: (context, index) {
                final m = muscles[index];
                final isSelected = m == _selectedMuscle;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(m, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : CyberTheme.textSecondary)),
                    selected: isSelected,
                    selectedColor: CyberTheme.cyberTeal.withOpacity(0.2),
                    checkmarkColor: CyberTheme.cyberTeal,
                    backgroundColor: CyberTheme.inputBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: CyberTheme.borderTranslucent)),
                    onSelected: (val) {
                      setState(() {
                        _selectedMuscle = m;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Exercises List
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: list.length,
              itemBuilder: (context, index) {
                final ex = list[index];
                final alreadyIn = widget.store.activeWorkout?.exercises.any((e) => e.id == ex.id) ?? false;
                
                return ListTile(
                  title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text("${ex.muscleGroup} • ${ex.equipment}", style: const TextStyle(color: CyberTheme.textSecondary, fontSize: 11)),
                  trailing: alreadyIn 
                      ? const Icon(Icons.check_circle, color: CyberTheme.cyberTeal)
                      : const Icon(Icons.add_circle_outline, color: CyberTheme.textSecondary),
                  onTap: () {
                    if (!alreadyIn) {
                      widget.store.addExerciseToActiveWorkout(ex);
                    }
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
