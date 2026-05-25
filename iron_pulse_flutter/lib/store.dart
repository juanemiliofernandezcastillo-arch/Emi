import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'db.dart';

class WorkoutStore extends ChangeNotifier {
  SharedPreferences? _prefs;
  bool _initialized = false;

  // App state
  List<WorkoutSession> _history = [];
  List<WorkoutRoutine> _routines = [];
  List<Exercise> _customExercises = [];
  WorkoutSession? _activeWorkout;
  
  // Settings
  String _weightUnit = 'kg';
  bool _soundEnabled = true;
  int _defaultRestTime = 90; // seconds

  // Rest Timer State
  Timer? _timer;
  int _restRemaining = 0;
  int _restTotal = 90;
  bool _isRestActive = false;

  // Active workout timer
  Timer? _activeWorkoutTimer;
  int _workoutElapsedSeconds = 0;

  // Getters
  bool get initialized => _initialized;
  List<WorkoutSession> get history => _history;
  List<WorkoutRoutine> get routines => _routines;
  List<Exercise> get customExercises => _customExercises;
  WorkoutSession? get activeWorkout => _activeWorkout;
  String get weightUnit => _weightUnit;
  bool get soundEnabled => _soundEnabled;
  int get defaultRestTime => _defaultRestTime;
  
  int get restRemaining => _restRemaining;
  int get restTotal => _restTotal;
  bool get isRestActive => _isRestActive;
  int get workoutElapsedSeconds => _workoutElapsedSeconds;

  WorkoutStore() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    // Listen to Auth State Changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        if (Supabase.instance.client.auth.currentUser != null) {
          await loadUserData();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        await clearUserData();
      }
    });

    // If already logged in, load immediately
    if (Supabase.instance.client.auth.currentUser != null) {
      await loadUserData();
    } else {
      // Load fallback/local settings/defaults if not logged in
      _weightUnit = _prefs?.getString('settings_weight_unit') ?? 'kg';
      _soundEnabled = _prefs?.getBool('settings_sound_enabled') ?? true;
      _defaultRestTime = _prefs?.getInt('settings_rest_time') ?? 90;
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch profiles (settings)
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (profileData != null) {
        _weightUnit = profileData['weight_unit'] as String? ?? 'kg';
        _soundEnabled = profileData['sound_enabled'] as bool? ?? true;
        _defaultRestTime = profileData['default_rest_time'] as int? ?? 90;
        
        await _prefs?.setString('settings_weight_unit', _weightUnit);
        await _prefs?.setBool('settings_sound_enabled', _soundEnabled);
        await _prefs?.setInt('settings_rest_time', _defaultRestTime);
      }

      // 2. Fetch custom exercises
      final customExData = await Supabase.instance.client
          .from('custom_exercises')
          .select()
          .eq('user_id', user.id);
      _customExercises = (customExData as List)
          .map((e) => Exercise.fromJson(e))
          .toList();
      await _prefs?.setString('custom_exercises', jsonEncode(_customExercises.map((e) => e.toJson()).toList()));

      // 3. Fetch routines
      final routinesData = await Supabase.instance.client
          .from('routines')
          .select()
          .eq('user_id', user.id);
      _routines = (routinesData as List)
          .map((e) => WorkoutRoutine.fromJson({
                'id': e['id'],
                'name': e['name'],
                'description': e['description'],
                'exerciseIds': e['exercise_ids'],
              }))
          .toList();

      if (_routines.isEmpty) {
        final defaultReps = [
          WorkoutRoutine(
            id: "routine_push_${DateTime.now().millisecondsSinceEpoch}",
            name: "Push Day",
            description: "Focus on chest, shoulders, and triceps.",
            exerciseIds: ["barbell_bench_press", "dumbbell_shoulder_press", "incline_dumbbell_press", "lateral_raise_dumbbell", "tricep_pushdown_cable"]
          ),
          WorkoutRoutine(
            id: "routine_pull_${DateTime.now().millisecondsSinceEpoch}",
            name: "Pull Day",
            description: "Targeting your back, biceps, and rear delts.",
            exerciseIds: ["pull_up", "barbell_row", "one_arm_dumbbell_row", "face_pull", "dumbbell_bicep_curl", "hammer_curl"]
          ),
          WorkoutRoutine(
            id: "routine_legs_${DateTime.now().millisecondsSinceEpoch}",
            name: "Leg Day",
            description: "Quad, hamstring, glute, and calf focused training.",
            exerciseIds: ["barbell_back_squat", "romanian_deadlift_barbell", "bulgarian_split_squat", "lying_leg_curl", "standing_calf_raise"]
          )
        ];
        for (var r in defaultReps) {
          await Supabase.instance.client.from('routines').insert({
            'id': r.id,
            'user_id': user.id,
            'name': r.name,
            'description': r.description,
            'exercise_ids': r.exerciseIds,
          });
        }
        _routines = defaultReps;
      }
      await _prefs?.setString('routines', jsonEncode(_routines.map((r) => r.toJson()).toList()));

      // 4. Fetch history
      final historyData = await Supabase.instance.client
          .from('history')
          .select()
          .eq('user_id', user.id)
          .order('start_time', ascending: false);
      _history = (historyData as List)
          .map((e) => WorkoutSession.fromJson({
                'id': e['id'],
                'name': e['name'],
                'startTime': e['start_time'],
                'endTime': e['end_time'],
                'exercises': e['exercises'],
                'durationInSeconds': e['duration_in_seconds'],
              }))
          .toList();
      await _prefs?.setString('history', jsonEncode(_history.map((h) => h.toJson()).toList()));

    } catch (e) {
      print("Error loading user data from Supabase, falling back to local storage: $e");
      _loadLocalFallback();
    }

    final activeJson = _prefs?.getString('active_workout');
    if (activeJson != null) {
      try {
        _activeWorkout = WorkoutSession.fromJson(jsonDecode(activeJson));
        _workoutElapsedSeconds = DateTime.now().difference(_activeWorkout!.startTime).inSeconds;
        _startActiveWorkoutTimer();
      } catch (e) {
        print("Error loading active workout: $e");
      }
    }

    _initialized = true;
    notifyListeners();
  }

  void _loadLocalFallback() {
    final customExJson = _prefs?.getString('custom_exercises');
    if (customExJson != null) {
      try {
        final List parsed = jsonDecode(customExJson);
        _customExercises = parsed.map((e) => Exercise.fromJson(e)).toList();
      } catch (_) {}
    }

    final routinesJson = _prefs?.getString('routines');
    if (routinesJson != null) {
      try {
        final List parsed = jsonDecode(routinesJson);
        _routines = parsed.map((e) => WorkoutRoutine.fromJson(e)).toList();
      } catch (_) {}
    }

    final historyJson = _prefs?.getString('history');
    if (historyJson != null) {
      try {
        final List parsed = jsonDecode(historyJson);
        _history = parsed.map((e) => WorkoutSession.fromJson(e)).toList();
      } catch (_) {}
    }

    _weightUnit = _prefs?.getString('settings_weight_unit') ?? 'kg';
    _soundEnabled = _prefs?.getBool('settings_sound_enabled') ?? true;
    _defaultRestTime = _prefs?.getInt('settings_rest_time') ?? 90;
  }

  Future<void> clearUserData() async {
    _history = [];
    _routines = [];
    _customExercises = [];
    _activeWorkout = null;
    cancelActiveWorkoutTimer();
    cancelRestTimer();
    
    await _prefs?.remove('custom_exercises');
    await _prefs?.remove('routines');
    await _prefs?.remove('history');
    await _prefs?.remove('active_workout');
    await _prefs?.remove('settings_weight_unit');
    await _prefs?.remove('settings_sound_enabled');
    await _prefs?.remove('settings_rest_time');

    _weightUnit = 'kg';
    _soundEnabled = true;
    _defaultRestTime = 90;
    
    notifyListeners();
  }

  // --- SAVE HELPERS ---
  Future<void> _saveHistory() async {
    final list = _history.map((h) => h.toJson()).toList();
    await _prefs?.setString('history', jsonEncode(list));
  }

  void deleteWorkoutFromHistory(String id) async {
    _history.removeWhere((w) => w.id == id);
    _saveHistory();
    notifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('history').delete().eq('id', id).eq('user_id', user.id);
      } catch (e) {
        print("Error deleting workout from Supabase: $e");
      }
    }
  }

  Future<void> _saveRoutines() async {
    final list = _routines.map((r) => r.toJson()).toList();
    await _prefs?.setString('routines', jsonEncode(list));
  }

  Future<void> _saveCustomExercises() async {
    final list = _customExercises.map((e) => e.toJson()).toList();
    await _prefs?.setString('custom_exercises', jsonEncode(list));
  }

  Future<void> _saveActiveWorkout() async {
    if (_activeWorkout != null) {
      await _prefs?.setString('active_workout', jsonEncode(_activeWorkout!.toJson()));
    } else {
      await _prefs?.remove('active_workout');
    }
  }

  // --- EXERCISE UTILS ---
  List<Exercise> get allExercises => [...defaultExercises, ..._customExercises];

  Exercise? getExerciseById(String id) {
    try {
      return allExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  void addCustomExercise(String name, String muscleGroup, String equipment, String instructions) async {
    final exercise = Exercise(
      id: "custom_${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      muscleGroup: muscleGroup,
      equipment: equipment,
      instructions: instructions
    );
    _customExercises.add(exercise);
    _saveCustomExercises();
    notifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('custom_exercises').insert({
          'id': exercise.id,
          'user_id': user.id,
          'name': exercise.name,
          'muscle_group': exercise.muscleGroup,
          'equipment': exercise.equipment,
          'instructions': exercise.instructions,
        });
      } catch (e) {
        print("Error adding custom exercise to Supabase: $e");
      }
    }
  }

  void deleteCustomExercise(String id) async {
    _customExercises.removeWhere((e) => e.id == id);
    _saveCustomExercises();
    notifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('custom_exercises').delete().eq('id', id).eq('user_id', user.id);
      } catch (e) {
        print("Error deleting custom exercise from Supabase: $e");
      }
    }
  }

  // --- ROUTINE UTILS ---
  void addRoutine(String name, String description, List<String> exerciseIds) async {
    final newRoutine = WorkoutRoutine(
      id: "routine_${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      description: description,
      exerciseIds: exerciseIds
    );
    _routines.add(newRoutine);
    _saveRoutines();
    notifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('routines').insert({
          'id': newRoutine.id,
          'user_id': user.id,
          'name': newRoutine.name,
          'description': newRoutine.description,
          'exercise_ids': newRoutine.exerciseIds,
        });
      } catch (e) {
        print("Error adding routine to Supabase: $e");
      }
    }
  }

  void updateRoutine(WorkoutRoutine routine) async {
    final idx = _routines.findIndex((r) => r.id == routine.id);
    if (idx != -1) {
      _routines[idx] = routine;
      _saveRoutines();
      notifyListeners();

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await Supabase.instance.client.from('routines').update({
            'name': routine.name,
            'description': routine.description,
            'exercise_ids': routine.exerciseIds,
          }).eq('id', routine.id).eq('user_id', user.id);
        } catch (e) {
          print("Error updating routine on Supabase: $e");
        }
      }
    }
  }

  void deleteRoutine(String id) async {
    _routines.removeWhere((r) => r.id == id);
    _saveRoutines();
    notifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('routines').delete().eq('id', id).eq('user_id', user.id);
      } catch (e) {
        print("Error deleting routine from Supabase: $e");
      }
    }
  }

  // --- ACTIVE WORKOUT CONTROL ---
  void startWorkout(String name, {List<String>? exerciseIds}) {
    // If there is an active workout, cancel it or overwrite
    cancelActiveWorkoutTimer();
    
    final List<LoggedExercise> loggedExercises = [];
    if (exerciseIds != null) {
      for (var id in exerciseIds) {
        final ex = getExerciseById(id);
        if (ex != null) {
          loggedExercises.add(LoggedExercise(
            id: ex.id,
            name: ex.name,
            sets: [SetLog(weight: 0.0, reps: 0, rir: -1, isCompleted: false)]
          ));
        }
      }
    }

    _activeWorkout = WorkoutSession(
      id: "session_${DateTime.now().millisecondsSinceEpoch}",
      name: name,
      startTime: DateTime.now(),
      exercises: loggedExercises,
      durationInSeconds: 0
    );
    _workoutElapsedSeconds = 0;
    _saveActiveWorkout();
    _startActiveWorkoutTimer();
    notifyListeners();
  }

  void addExerciseToActiveWorkout(Exercise exercise) {
    if (_activeWorkout == null) return;
    
    // Check if exercise is already added
    final exists = _activeWorkout!.exercises.any((e) => e.id == exercise.id);
    if (exists) return;

    final updated = List<LoggedExercise>.from(_activeWorkout!.exercises);
    updated.add(LoggedExercise(
      id: exercise.id,
      name: exercise.name,
      sets: [SetLog(weight: 0.0, reps: 0, rir: -1, isCompleted: false)]
    ));

    _activeWorkout = _activeWorkout!.copyWith(exercises: updated);
    _saveActiveWorkout();
    notifyListeners();
  }

  void removeExerciseFromActiveWorkout(String id) {
    if (_activeWorkout == null) return;

    final updated = _activeWorkout!.exercises.where((e) => e.id != id).toList();
    _activeWorkout = _activeWorkout!.copyWith(exercises: updated);
    _saveActiveWorkout();
    notifyListeners();
  }

  void addSetToExercise(String exerciseId) {
    if (_activeWorkout == null) return;

    final updated = _activeWorkout!.exercises.map((ex) {
      if (ex.id == exerciseId) {
        final sets = List<SetLog>.from(ex.sets);
        // Copy previous set values for convenience
        final lastSet = sets.isNotEmpty ? sets.last : SetLog();
        sets.add(SetLog(
          weight: lastSet.weight,
          reps: lastSet.reps,
          rir: lastSet.rir,
          isCompleted: false
        ));
        return ex.copyWith(sets: sets);
      }
      return ex;
    }).toList();

    _activeWorkout = _activeWorkout!.copyWith(exercises: updated);
    _saveActiveWorkout();
    notifyListeners();
  }

  void removeSetFromExercise(String exerciseId, int setIndex) {
    if (_activeWorkout == null) return;

    final updated = _activeWorkout!.exercises.map((ex) {
      if (ex.id == exerciseId) {
        final sets = List<SetLog>.from(ex.sets);
        if (sets.length > setIndex) {
          sets.removeAt(setIndex);
        }
        return ex.copyWith(sets: sets);
      }
      return ex;
    }).toList();

    _activeWorkout = _activeWorkout!.copyWith(exercises: updated);
    _saveActiveWorkout();
    notifyListeners();
  }

  void updateSet(String exerciseId, int setIndex, SetLog setLog) {
    if (_activeWorkout == null) return;

    final updated = _activeWorkout!.exercises.map((ex) {
      if (ex.id == exerciseId) {
        final sets = List<SetLog>.from(ex.sets);
        if (sets.length > setIndex) {
          final wasCompleted = sets[setIndex].isCompleted;
          sets[setIndex] = setLog;
          
          // Trigger rest timer if set was newly marked complete
          if (!wasCompleted && setLog.isCompleted) {
            startRestTimer(_defaultRestTime);
          }
        }
        return ex.copyWith(sets: sets);
      }
      return ex;
    }).toList();

    _activeWorkout = _activeWorkout!.copyWith(exercises: updated);
    _saveActiveWorkout();
    notifyListeners();
  }

  void finishWorkout() async {
    if (_activeWorkout == null) return;

    cancelActiveWorkoutTimer();
    
    // Filter out exercises with no completed sets
    final cleanExercises = _activeWorkout!.exercises.map((ex) {
      final completedSets = ex.sets.where((s) => s.isCompleted).toList();
      return ex.copyWith(sets: completedSets);
    }).where((ex) => ex.sets.isNotEmpty).toList();

    if (cleanExercises.isNotEmpty) {
      final completedSession = _activeWorkout!.copyWith(
        endTime: DateTime.now(),
        exercises: cleanExercises,
        durationInSeconds: _workoutElapsedSeconds
      );
      
      _history.insert(0, completedSession);
      _saveHistory();

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await Supabase.instance.client.from('history').insert({
            'id': completedSession.id,
            'user_id': user.id,
            'name': completedSession.name,
            'start_time': completedSession.startTime.toIso8601String(),
            'end_time': completedSession.endTime?.toIso8601String(),
            'exercises': completedSession.exercises.map((e) => e.toJson()).toList(),
            'duration_in_seconds': completedSession.durationInSeconds,
          });
        } catch (e) {
          print("Error saving workout history to Supabase: $e");
        }
      }
    }

    _activeWorkout = null;
    _workoutElapsedSeconds = 0;
    _saveActiveWorkout();
    cancelRestTimer();
    notifyListeners();
  }

  void discardWorkout() {
    cancelActiveWorkoutTimer();
    _activeWorkout = null;
    _workoutElapsedSeconds = 0;
    _saveActiveWorkout();
    cancelRestTimer();
    notifyListeners();
  }

  // --- SETTINGS CONTROLS ---
  void updateSettings({String? unit, bool? sound, int? restTime}) async {
    if (unit != null) {
      _weightUnit = unit;
      _prefs?.setString('settings_weight_unit', unit);
    }
    if (sound != null) {
      _soundEnabled = sound;
      _prefs?.setBool('settings_sound_enabled', sound);
    }
    if (restTime != null) {
      _defaultRestTime = restTime;
      _prefs?.setInt('settings_rest_time', restTime);
    }
    notifyListeners();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'updated_at': DateTime.now().toIso8601String(),
          'weight_unit': _weightUnit,
          'sound_enabled': _soundEnabled,
          'default_rest_time': _defaultRestTime,
        });
      } catch (e) {
        print("Error updating profile settings on Supabase: $e");
      }
    }
  }

  // --- TIMER CONTROLS ---
  void startRestTimer(int seconds) {
    cancelRestTimer();
    _restTotal = seconds;
    _restRemaining = seconds;
    _isRestActive = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemaining > 1) {
        _restRemaining--;
        notifyListeners();
      } else {
        _restRemaining = 0;
        _isRestActive = false;
        _timer?.cancel();
        notifyListeners();
        _triggerRestAlert();
      }
    });
  }

  void cancelRestTimer() {
    _timer?.cancel();
    _isRestActive = false;
    _restRemaining = 0;
    notifyListeners();
  }

  void adjustTimer(int seconds) {
    if (!_isRestActive) return;
    _restRemaining = (_restRemaining + seconds).clamp(0, 999);
    if (_restRemaining == 0) {
      cancelRestTimer();
    } else {
      notifyListeners();
    }
  }

  void _triggerRestAlert() {
    if (!_soundEnabled) return;
    // Synthesize haptic vibration feedback for device users
    HapticFeedback.vibrate();
    HapticFeedback.vibrate();
    
    // Play system beep sound
    SystemSound.play(SystemSoundType.click);
    Future.delayed(const Duration(milliseconds: 300), () {
      SystemSound.play(SystemSoundType.click);
    });
  }

  // --- ACTIVE WORKOUT TIMER ---
  void _startActiveWorkoutTimer() {
    _activeWorkoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _workoutElapsedSeconds++;
      notifyListeners();
    });
  }

  void cancelActiveWorkoutTimer() {
    _activeWorkoutTimer?.cancel();
  }

  @override
  void dispose() {
    cancelActiveWorkoutTimer();
    cancelRestTimer();
    super.dispose();
  }

  // --- ANALYTICS CALCULATIONS ---
  
  // Weekly Consistency Heatmap Data: returns a map of Date -> WorkoutCount
  Map<DateTime, int> getWeeklyConsistency() {
    final Map<DateTime, int> consistency = {};
    final now = DateTime.now();
    // Return last 28 days
    for (int i = 0; i < 28; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      consistency[date] = 0;
    }

    for (var w in _history) {
      final date = DateTime(w.startTime.year, w.startTime.month, w.startTime.day);
      if (consistency.containsKey(date)) {
        consistency[date] = (consistency[date] ?? 0) + 1;
      }
    }
    return consistency;
  }

  // Max 1RM Progression for an exercise over time
  List<Map<String, dynamic>> getExerciseProgress(String exerciseId) {
    final List<Map<String, dynamic>> progress = [];
    final chronologicalHistory = List<WorkoutSession>.from(_history).reversed;

    for (var session in chronologicalHistory) {
      final match = session.exercises.where((e) => e.id == exerciseId);
      if (match.isNotEmpty) {
        final completedSets = match.first.sets.where((s) => s.isCompleted);
        if (completedSets.isNotEmpty) {
          // Calculate max 1RM: weight * (1 + reps / 30)
          double max1RM = 0.0;
          for (var s in completedSets) {
            final double est1RM = s.reps == 1 ? s.weight : s.weight * (1 + s.reps / 30.0);
            if (est1RM > max1RM) {
              max1RM = est1RM;
            }
          }
          
          progress.add({
            'date': "${session.startTime.month}/${session.startTime.day}",
            '1rm': max1RM
          });
        }
      }
    }
    return progress;
  }

  // Training volume per muscle group
  Map<String, double> getVolumeByMuscleGroup() {
    final Map<String, double> volume = {};
    for (var group in muscleGroups) {
      volume[group] = 0.0;
    }

    for (var session in _history) {
      for (var ex in session.exercises) {
        final detail = getExerciseById(ex.id);
        final group = detail?.muscleGroup ?? "Core";
        
        double exerciseVolume = 0.0;
        for (var s in ex.sets) {
          if (s.isCompleted) {
            exerciseVolume += s.weight * s.reps;
          }
        }
        volume[group] = (volume[group] ?? 0.0) + exerciseVolume;
      }
    }
    return volume;
  }
}

// Extension to find item in List index by condition
extension FindIndex<T> on List<T> {
  int findIndex(bool Function(T) test) {
    for (int i = 0; i < length; i++) {
      if (test(this[i])) return i;
    }
    return -1;
  }
}
