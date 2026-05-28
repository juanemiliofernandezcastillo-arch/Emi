import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../models.dart';
import '../../../services/classes_service.dart';

class ManageClassScreen extends StatefulWidget {
  final int initialIndex;
  const ManageClassScreen({super.key, this.initialIndex = 0});

  @override
  State<ManageClassScreen> createState() => _ManageClassScreenState();
}

class _ManageClassScreenState extends State<ManageClassScreen> with SingleTickerProviderStateMixin {
  final Color primary = const Color(0xFF17A1CF);
  final Color bgDark = const Color(0xFF121416);
  final Color surfaceDark = const Color(0xFF1A1D21);
  final Color slate400 = const Color(0xFF94A3B8);
  final Color slate500 = const Color(0xFF64748B);
  final Color slate800 = const Color(0xFF1E293B);

  late TabController _tabController;
  final ClassesService _classesService = ClassesService();

  List<ClassModel> _classes = [];
  List<ClassSchedule> _schedules = [];
  List<Category> _categories = [];
  List<Profile> _instructors = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _classesService.getClasses(),
        _classesService.getUpcomingSchedules(),
        _classesService.getCategories(),
        _classesService.getInstructors(),
      ]);

      setState(() {
        _classes = futures[0] as List<ClassModel>;
        _schedules = futures[1] as List<ClassSchedule>;
        _schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
        _categories = futures[2] as List<Category>;
        _instructors = futures[3] as List<Profile>;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error cargando datos: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        title: const Text('Gestión de Clases', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor: slate400,
          tabs: const [
            Tab(text: 'Clases (Plantillas)'),
            Tab(text: 'Sesiones Programadas'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildClassesTab(),
                _buildSchedulesTab(),
              ],
            ),
    );
  }

  // --- TAB: CLASES ---
  Widget _buildClassesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: primary,
      backgroundColor: surfaceDark,
      child: Stack(
        children: [
          _classes.isEmpty
              ? const Center(child: Text("No hay clases creadas", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final cls = _classes[index];
                    return Card(
                      color: surfaceDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: cls.imageUrl != null && cls.imageUrl!.isNotEmpty
                              ? Image.network(cls.imageUrl!, width: 50, height: 50, fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(color: slate800, width: 50, height: 50, child: const Icon(Icons.broken_image, color: Colors.white54)))
                              : Container(color: slate800, width: 50, height: 50, child: const Icon(Icons.image, color: Colors.white54)),
                        ),
                        title: Text(cls.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("${cls.durationMinutes} min • \$${cls.basePrice}", style: TextStyle(color: slate400)),
                        trailing: IconButton(
                          icon: Icon(Icons.edit, color: primary),
                          onPressed: () => _showClassDialog(cls),
                        ),
                      ),
                    );
                  },
                ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              heroTag: 'fab_class',
              backgroundColor: primary,
              onPressed: () => _showClassDialog(null),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Nueva Clase", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // --- TAB: SESIONES ---
  Widget _buildSchedulesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: primary,
      backgroundColor: surfaceDark,
      child: Stack(
        children: [
          _schedules.isEmpty
              ? const Center(child: Text("No hay sesiones programadas", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                  itemCount: _schedules.length,
                  itemBuilder: (context, index) {
                    final sched = _schedules[index];
                    final DateFormat formatter = DateFormat("d 'de' MMMM yyyy, HH:mm", "es_ES");
                    return Card(
                      color: surfaceDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(sched.classModel?.name ?? 'Clase desconocida', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(formatter.format(sched.startTime), style: TextStyle(color: slate400)),
                            Text("Cupos: ${sched.bookedCount ?? 0}/${sched.capacity}", style: TextStyle(color: slate400)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: primary),
                              onPressed: () => _showScheduleDialog(sched),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteSchedule(sched),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              heroTag: 'fab_sched',
              backgroundColor: primary,
              onPressed: () => _showScheduleDialog(null),
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              label: const Text("Programar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // --- DIALOGS & LOGIC ---

  Future<void> _deleteSchedule(ClassSchedule sched) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: surfaceDark,
        title: const Text("Eliminar Sesión", style: TextStyle(color: Colors.white)),
        content: const Text("¿Estás seguro de eliminar esta sesión?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("Cancelar", style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _classesService.deleteSchedule(sched.id);
        await _loadData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showClassDialog(ClassModel? cls) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClassForm(
        initialData: cls,
        categories: _categories,
        instructors: _instructors,
        classesService: _classesService,
        onSaved: () => _loadData(),
      ),
    );
  }

  Future<void> _showScheduleDialog(ClassSchedule? sched) async {
    if (_classes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes crear al menos una clase primero')));
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScheduleForm(
        initialData: sched,
        classes: _classes,
        instructors: _instructors,
        classesService: _classesService,
        onSaved: () => _loadData(),
      ),
    );
  }
}

class _ClassForm extends StatefulWidget {
  final ClassModel? initialData;
  final List<Category> categories;
  final List<Profile> instructors;
  final ClassesService classesService;
  final VoidCallback onSaved;

  const _ClassForm({this.initialData, required this.categories, required this.instructors, required this.classesService, required this.onSaved});

  @override
  State<_ClassForm> createState() => _ClassFormState();
}

class _ClassFormState extends State<_ClassForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _priceCtrl;
  Category? _selectedCategory;
  ClassIntensity _selectedIntensity = ClassIntensity.medium;
  File? _imageFile;
  String? _existingImageUrl;
  bool _isSaving = false;

  // Campos para programar (solo en creación)
  Profile? _selectedInstructor;
  late TextEditingController _capacityCtrl;
  late TextEditingController _locationCtrl;
  DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  DateTime _endTime = DateTime.now().add(const Duration(days: 1, hours: 1));
  bool _isLive = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialData?.name);
    _descCtrl = TextEditingController(text: widget.initialData?.description);
    _durationCtrl = TextEditingController(text: widget.initialData?.durationMinutes.toString() ?? '60');
    _priceCtrl = TextEditingController(text: widget.initialData?.basePrice.toString() ?? '0');
    _existingImageUrl = widget.initialData?.imageUrl;
    
    if (widget.initialData != null && widget.categories.isNotEmpty) {
      try {
        _selectedCategory = widget.categories.firstWhere((c) => c.id == widget.initialData!.categoryId);
      } catch (_) {}
      _selectedIntensity = widget.initialData!.intensity;
    }
    
    _capacityCtrl = TextEditingController(text: '20');
    _locationCtrl = TextEditingController(text: '');
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      );
      if (time != null) {
        setState(() {
          final newDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (isStart) {
            _startTime = newDt;
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 1));
            }
          } else {
            _endTime = newDt;
          }
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        imageUrl = await widget.classesService.uploadClassImage(_imageFile!);
      }

      final newClass = ClassModel(
        id: widget.initialData?.id ?? '', // empty for create, db handles it or ignores it via json
        name: _nameCtrl.text,
        description: _descCtrl.text,
        durationMinutes: int.tryParse(_durationCtrl.text) ?? 60,
        basePrice: double.tryParse(_priceCtrl.text) ?? 0.0,
        categoryId: _selectedCategory?.id,
        intensity: _selectedIntensity,
        imageUrl: imageUrl,
      );

      if (widget.initialData == null) {
        final createdClass = await widget.classesService.createClass(newClass);
        // Crear la primera sesión programada
        final newSched = ClassSchedule(
          id: '',
          classId: createdClass.id,
          instructorId: _selectedInstructor?.id,
          startTime: _startTime,
          endTime: _endTime,
          capacity: int.tryParse(_capacityCtrl.text) ?? 20,
          locationName: _locationCtrl.text,
          isLive: _isLive,
        );
        await widget.classesService.createSchedule(newSched);
      } else {
        await widget.classesService.updateClass(newClass);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = const Color(0xFF1A1D21);
    
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.initialData == null ? "Crear Clase" : "Editar Clase", 
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24),
                      image: _imageFile != null
                          ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                          : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                              ? DecorationImage(image: NetworkImage(_existingImageUrl!), fit: BoxFit.cover)
                              : null),
                    ),
                    child: (_imageFile == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty))
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.white54, size: 32),
                              SizedBox(height: 8),
                              Text("Subir Imagen (Opcional)", style: TextStyle(color: Colors.white54)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Nombre de Clase"),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: _inputDecoration("Descripción"),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Duración (min)"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Precio (\$)"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                dropdownColor: surfaceColor,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Categoría"),
                items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<ClassIntensity>(
                value: _selectedIntensity,
                dropdownColor: surfaceColor,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Intensidad"),
                items: ClassIntensity.values.map((i) => DropdownMenuItem(value: i, child: Text(i.name.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _selectedIntensity = v!),
              ),
              const SizedBox(height: 24),

              if (widget.initialData == null) ...[
                const Divider(color: Colors.white24),
                const SizedBox(height: 12),
                const Text("Primera Sesión (Opcional)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                DropdownButtonFormField<Profile>(
                  value: _selectedInstructor,
                  dropdownColor: surfaceColor,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Instructor (Opcional)"),
                  items: widget.instructors.map((c) => DropdownMenuItem(value: c, child: Text(c.fullName ?? 'Sin nombre'))).toList(),
                  onChanged: (v) => setState(() => _selectedInstructor = v),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDateTime(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Inicio", style: TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(DateFormat('dd MMM, h:mm a').format(_startTime), style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDateTime(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Fin", style: TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(DateFormat('dd MMM, h:mm a').format(_endTime), style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _capacityCtrl,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration("Capacidad"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _locationCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration("Ubicación/Sala"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF17A1CF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Guardar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

class _ScheduleForm extends StatefulWidget {
  final ClassSchedule? initialData;
  final List<ClassModel> classes;
  final List<Profile> instructors;
  final ClassesService classesService;
  final VoidCallback onSaved;

  const _ScheduleForm({this.initialData, required this.classes, required this.instructors, required this.classesService, required this.onSaved});

  @override
  State<_ScheduleForm> createState() => _ScheduleFormState();
}

class _ScheduleFormState extends State<_ScheduleForm> {
  final _formKey = GlobalKey<FormState>();
  ClassModel? _selectedClass;
  Profile? _selectedInstructor;
  late TextEditingController _capacityCtrl;
  late TextEditingController _locationCtrl;
  DateTime _startTime = DateTime.now().add(const Duration(days: 1));
  DateTime _endTime = DateTime.now().add(const Duration(days: 1, hours: 1));
  bool _isLive = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _capacityCtrl = TextEditingController(text: widget.initialData?.capacity.toString() ?? '20');
    _locationCtrl = TextEditingController(text: widget.initialData?.locationName);
    
    if (widget.initialData != null) {
      _startTime = widget.initialData!.startTime;
      _endTime = widget.initialData!.endTime;
      _isLive = widget.initialData!.isLive;
      try {
        _selectedClass = widget.classes.firstWhere((c) => c.id == widget.initialData!.classId);
        if (widget.initialData!.instructorId != null) {
          _selectedInstructor = widget.instructors.firstWhere((i) => i.id == widget.initialData!.instructorId);
        }
      } catch (_) {}
    } else if (widget.classes.isNotEmpty) {
      _selectedClass = widget.classes.first;
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startTime : _endTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStart ? _startTime : _endTime),
      );
      if (time != null) {
        setState(() {
          final newDt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (isStart) {
            _startTime = newDt;
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 1));
            }
          } else {
            _endTime = newDt;
          }
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClass == null) return;
    
    setState(() => _isSaving = true);

    try {
      final newSched = ClassSchedule(
        id: widget.initialData?.id ?? '',
        classId: _selectedClass!.id,
        instructorId: _selectedInstructor?.id,
        startTime: _startTime,
        endTime: _endTime,
        capacity: int.tryParse(_capacityCtrl.text) ?? 20,
        locationName: _locationCtrl.text,
        isLive: _isLive,
      );

      if (widget.initialData == null) {
        await widget.classesService.createSchedule(newSched);
      } else {
        await widget.classesService.updateSchedule(newSched);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = const Color(0xFF1A1D21);
    final DateFormat formatter = DateFormat('dd MMM yyyy, h:mm a');
    
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.initialData == null ? "Programar Sesión" : "Editar Sesión", 
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              DropdownButtonFormField<ClassModel>(
                value: _selectedClass,
                dropdownColor: surfaceColor,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Clase Base"),
                items: widget.classes.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _selectedClass = v),
                validator: (v) => v == null ? "Requerido" : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<Profile>(
                value: _selectedInstructor,
                dropdownColor: surfaceColor,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Instructor (Opcional)"),
                items: widget.instructors.map((c) => DropdownMenuItem(value: c, child: Text(c.fullName ?? 'Sin nombre'))).toList(),
                onChanged: (v) => setState(() => _selectedInstructor = v),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDateTime(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Inicio", style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(formatter.format(_startTime), style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDateTime(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Fin", style: TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(formatter.format(_endTime), style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacityCtrl,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration("Capacidad"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _locationCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration("Ubicación/Sala"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              SwitchListTile(
                title: const Text("En Vivo (Live Stream)", style: TextStyle(color: Colors.white)),
                activeColor: const Color(0xFF17A1CF),
                value: _isLive,
                onChanged: (v) => setState(() => _isLive = v),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF17A1CF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Guardar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
