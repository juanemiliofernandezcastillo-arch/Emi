import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../store.dart';
import '../models.dart';
import '../db.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _searchQuery = "";
  String _selectedMuscle = "Todos";
  String _selectedEquipment = "Todos";

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    
    // Filters
    final exercises = store.allExercises.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMuscle = _selectedMuscle == "Todos" || e.muscleGroup == _selectedMuscle;
      final matchesEquip = _selectedEquipment == "Todos" || e.equipment == _selectedEquipment;
      return matchesSearch && matchesMuscle && matchesEquip;
    }).toList();

    final muscles = ["Todos", ...muscleGroups];
    final equipments = ["Todos", ...equipmentTypes];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateExerciseSheet(context, store),
        backgroundColor: CyberTheme.cyberTeal,
        foregroundColor: CyberTheme.background,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filter section
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
            child: Column(
              children: [
                // Search field
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Buscar en biblioteca de ejercicios...",
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Muscle filter list
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Músculo:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CyberTheme.textSecondary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: muscles.length,
                          itemBuilder: (context, index) {
                            final m = muscles[index];
                            final isSelected = m == _selectedMuscle;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text(m, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : CyberTheme.textSecondary)),
                                selected: isSelected,
                                selectedColor: CyberTheme.cyberTeal.withOpacity(0.2),
                                checkmarkColor: CyberTheme.cyberTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSelected ? CyberTheme.cyberTeal.withOpacity(0.5) : CyberTheme.borderTranslucent)),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _selectedMuscle = m;
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Equipment filter list
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Equip:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CyberTheme.textSecondary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 34,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: equipments.length,
                          itemBuilder: (context, index) {
                            final eq = equipments[index];
                            final isSelected = eq == _selectedEquipment;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: ChoiceChip(
                                label: Text(eq, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : CyberTheme.textSecondary)),
                                selected: isSelected,
                                selectedColor: CyberTheme.cyberTeal.withOpacity(0.2),
                                checkmarkColor: CyberTheme.cyberTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSelected ? CyberTheme.cyberTeal.withOpacity(0.5) : CyberTheme.borderTranslucent)),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() {
                                      _selectedEquipment = eq;
                                    });
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: CyberTheme.borderTranslucent, height: 24),

          // Exercise List
          Expanded(
            child: exercises.isEmpty
                ? const Center(child: Text("No se encontraron ejercicios", style: TextStyle(color: CyberTheme.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final ex = exercises[index];
                      final isCustom = ex.id.startsWith("custom_");

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Text(
                                ex.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                              if (isCustom) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: CyberTheme.cyberTeal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: CyberTheme.cyberTeal.withOpacity(0.3)),
                                  ),
                                  child: const Text("PROPIO", style: TextStyle(fontSize: 8, color: CyberTheme.cyberTeal, fontWeight: FontWeight.bold)),
                                )
                              ]
                            ],
                          ),
                          subtitle: Text(
                            "${ex.muscleGroup} • ${ex.equipment}",
                            style: const TextStyle(color: CyberTheme.textSecondary, fontSize: 11),
                          ),
                          trailing: isCustom 
                              ? IconButton(
                                  icon: const Icon(Icons.delete_outline, color: CyberTheme.neonRose, size: 20),
                                  onPressed: () {
                                    _confirmDeleteCustom(context, store, ex);
                                  },
                                )
                              : null,
                          childrenPadding: const EdgeInsets.all(16),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("INSTRUCCIONES:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CyberTheme.cyberTeal, letterSpacing: 1.0)),
                                  const SizedBox(height: 6),
                                  Text(
                                    ex.instructions.isNotEmpty ? ex.instructions : "Sin instrucciones provistas.",
                                    style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 80), // spacer for timer
        ],
      ),
    );
  }

  void _confirmDeleteCustom(BuildContext context, WorkoutStore store, Exercise ex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿ELIMINAR EJERCICIO?"),
        content: Text("¿Estás seguro de que quieres eliminar '${ex.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () {
              store.deleteCustomExercise(ex.id);
              Navigator.pop(context);
            },
            child: const Text("ELIMINAR", style: TextStyle(color: CyberTheme.neonRose)),
          ),
        ],
      ),
    );
  }

  void _showCreateExerciseSheet(BuildContext context, WorkoutStore store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: CyberTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return CreateExerciseForm(store: store, scrollController: scrollController);
          },
        );
      },
    );
  }
}

// Custom Exercise registration form sheet
class CreateExerciseForm extends StatefulWidget {
  final WorkoutStore store;
  final ScrollController scrollController;

  const CreateExerciseForm({super.key, required this.store, required this.scrollController});

  @override
  State<CreateExerciseForm> createState() => _CreateExerciseFormState();
}

class _CreateExerciseFormState extends State<CreateExerciseForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String _selectedMuscle = muscleGroups.first;
  String _selectedEquipment = equipmentTypes.first;

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Form(
        key: _formKey,
        child: ListView(
          controller: widget.scrollController,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CyberTheme.borderTranslucent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                "CREAR EJERCICIO PERSONALIZADO",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
              ),
            ),
            const SizedBox(height: 16),

            // Exercise Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nombre del Ejercicio",
                hintText: "ej. Cruces en polea alta",
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return "Por favor, ingresa un nombre para el ejercicio";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Muscle Group Dropdown
            DropdownButtonFormField<String>(
              value: _selectedMuscle,
              decoration: const InputDecoration(labelText: "Grupo Muscular Principal"),
              dropdownColor: CyberTheme.surface,
              items: muscleGroups.map((group) {
                return DropdownMenuItem(value: group, child: Text(group));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedMuscle = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Equipment Dropdown
            DropdownButtonFormField<String>(
              value: _selectedEquipment,
              decoration: const InputDecoration(labelText: "Tipo de Equipamiento"),
              dropdownColor: CyberTheme.surface,
              items: equipmentTypes.map((equip) {
                return DropdownMenuItem(value: equip, child: Text(equip));
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedEquipment = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Instructions Text Field
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: "Instrucciones (Opcional)",
                hintText: "Describe la postura, configuración o alineación...",
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Actions Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("CANCELAR"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.store.addCustomExercise(
                          _nameController.text.trim(),
                          _selectedMuscle,
                          _selectedEquipment,
                          _instructionsController.text.trim(),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.cyberTeal),
                    child: const Text("GUARDAR EJERCICIO", style: TextStyle(color: CyberTheme.background, fontWeight: FontWeight.bold)),
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
