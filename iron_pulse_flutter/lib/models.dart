class Exercise {
  final String id;
  final String name;
  final String muscleGroup;
  final String equipment;
  final String instructions;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.instructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'equipment': equipment,
      'instructions': instructions,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      muscleGroup: json['muscleGroup'] as String,
      equipment: json['equipment'] as String,
      instructions: json['instructions'] as String,
    );
  }
}

class SetLog {
  final double weight;
  final int reps;
  final int rir; // Reps In Reserve (-1 = unset or to failure)
  final bool isCompleted;

  SetLog({
    this.weight = 0.0,
    this.reps = 0,
    this.rir = -1,
    this.isCompleted = false,
  });

  SetLog copyWith({
    double? weight,
    int? reps,
    int? rir,
    bool? isCompleted,
  }) {
    return SetLog(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      rir: rir ?? this.rir,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weight': weight,
      'reps': reps,
      'rir': rir,
      'isCompleted': isCompleted,
    };
  }

  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      rir: json['rir'] as int,
      isCompleted: json['isCompleted'] as bool,
    );
  }
}

class LoggedExercise {
  final String id;
  final String name;
  final List<SetLog> sets;

  LoggedExercise({
    required this.id,
    required this.name,
    required this.sets,
  });

  LoggedExercise copyWith({
    String? id,
    String? name,
    List<SetLog>? sets,
  }) {
    return LoggedExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }

  factory LoggedExercise.fromJson(Map<String, dynamic> json) {
    var setsList = json['sets'] as List;
    return LoggedExercise(
      id: json['id'] as String,
      name: json['name'] as String,
      sets: setsList.map((s) => SetLog.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }
}

class WorkoutSession {
  final String id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final List<LoggedExercise> exercises;
  final int durationInSeconds;

  WorkoutSession({
    required this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.durationInSeconds = 0,
  });

  WorkoutSession copyWith({
    String? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    List<LoggedExercise>? exercises,
    int? durationInSeconds,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exercises: exercises ?? this.exercises,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
    );
  }

  // Helper to calculate total volume of completed sets
  double get totalVolume {
    double total = 0.0;
    for (var ex in exercises) {
      for (var s in ex.sets) {
        if (s.isCompleted) {
          total += s.weight * s.reps;
        }
      }
    }
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'durationInSeconds': durationInSeconds,
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    var exList = json['exercises'] as List;
    return WorkoutSession(
      id: json['id'] as String,
      name: json['name'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      exercises: exList.map((e) => LoggedExercise.fromJson(e as Map<String, dynamic>)).toList(),
      durationInSeconds: json['durationInSeconds'] as int? ?? 0,
    );
  }
}

class WorkoutRoutine {
  final String id;
  final String name;
  final String description;
  final List<String> exerciseIds;

  WorkoutRoutine({
    required this.id,
    required this.name,
    required this.description,
    required this.exerciseIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'exerciseIds': exerciseIds,
    };
  }

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    return WorkoutRoutine(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      exerciseIds: List<String>.from(json['exerciseIds'] as List),
    );
  }
}
