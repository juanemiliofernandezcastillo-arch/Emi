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

// --- NEW BOOKING MODELS ---

enum UserRole { admin, client }

UserRole _parseUserRole(String? value) {
  if (value == 'admin') return UserRole.admin;
  return UserRole.client;
}

String _roleToString(UserRole role) {
  return role == UserRole.admin ? 'admin' : 'client';
}

enum BookingStatus { confirmed, waitlist, cancelled }

BookingStatus _parseBookingStatus(String? value) {
  if (value == 'waitlist') return BookingStatus.waitlist;
  if (value == 'cancelled') return BookingStatus.cancelled;
  return BookingStatus.confirmed;
}

String _statusToString(BookingStatus status) {
  if (status == BookingStatus.waitlist) return 'waitlist';
  if (status == BookingStatus.cancelled) return 'cancelled';
  return 'confirmed';
}

enum ClassIntensity { low, medium, high }

ClassIntensity _parseIntensity(String? value) {
  if (value == 'Low' || value == 'low') return ClassIntensity.low;
  if (value == 'High' || value == 'high') return ClassIntensity.high;
  return ClassIntensity.medium;
}

String _intensityToString(ClassIntensity intensity) {
  if (intensity == ClassIntensity.low) return 'Low';
  if (intensity == ClassIntensity.high) return 'High';
  return 'Medium';
}

class Profile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final UserRole role;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.role = UserRole.client,
    required this.updatedAt,
  });

  Profile copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    UserRole? role,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: _parseUserRole(json['role'] as String?),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'].toString()) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': _roleToString(role),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Category {
  final String id;
  final String name;
  final String? iconUrl;

  Category({
    required this.id,
    required this.name,
    this.iconUrl,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      iconUrl: json['icon_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Instructor {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;
  final double rating;

  Instructor({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
    this.rating = 5.0,
  });

  factory Instructor.fromJson(Map<String, dynamic> json) {
    return Instructor(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'bio': bio,
      'rating': rating,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Instructor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ClassModel {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? categoryId;
  final ClassIntensity intensity;
  final int durationMinutes;
  final double basePrice;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.categoryId,
    this.intensity = ClassIntensity.medium,
    required this.durationMinutes,
    this.basePrice = 0.0,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id'] as String?,
      intensity: _parseIntensity(json['intensity'] as String?),
      durationMinutes: json['duration_minutes'] as int? ?? 60,
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'category_id': categoryId,
      'intensity': _intensityToString(intensity),
      'duration_minutes': durationMinutes,
      'base_price': basePrice,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ClassSchedule {
  final String id;
  final String classId;
  final String? instructorId;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final String? locationName;
  final bool isLive;

  // For nested relations
  final ClassModel? classModel;
  final Instructor? instructor;
  final int? bookedCount;

  ClassSchedule({
    required this.id,
    required this.classId,
    this.instructorId,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    this.locationName,
    this.isLive = false,
    this.classModel,
    this.instructor,
    this.bookedCount,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      instructorId: json['instructor_id'] as String?,
      startTime: DateTime.parse(json['start_time'].toString()),
      endTime: DateTime.parse(json['end_time'].toString()),
      capacity: json['capacity'] as int? ?? 0,
      locationName: json['location_name'] as String?,
      isLive: json['is_live'] as bool? ?? false,
      classModel: json['classes'] != null ? ClassModel.fromJson(json['classes']) : null,
      instructor: json['instructors'] != null ? Instructor.fromJson(json['instructors']) : null,
      bookedCount: json['booked_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'instructor_id': instructorId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'capacity': capacity,
      'location_name': locationName,
      'is_live': isLive,
    };
  }
  
  int get availableSpots {
    return capacity - (bookedCount ?? 0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassSchedule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Booking {
  final String id;
  final String userId;
  final String scheduleId;
  final BookingStatus status;
  final bool isPresent;
  final DateTime createdAt;

  // Relations
  final Profile? profile;
  final ClassSchedule? schedule;

  Booking({
    required this.id,
    required this.userId,
    required this.scheduleId,
    this.status = BookingStatus.confirmed,
    this.isPresent = false,
    required this.createdAt,
    this.profile,
    this.schedule,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scheduleId: json['schedule_id'] as String,
      status: _parseBookingStatus(json['status'] as String?),
      isPresent: json['is_present'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'].toString()),
      profile: json['profiles'] != null ? Profile.fromJson(json['profiles']) : null,
      schedule: json['class_schedules'] != null ? ClassSchedule.fromJson(json['class_schedules']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'schedule_id': scheduleId,
      'status': _statusToString(status),
      'is_present': isPresent,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Message {
  final String id;
  final String? senderId;
  final String? subject;
  final String? content;
  final bool isRead;
  final String? category;
  final DateTime createdAt;

  Message({
    required this.id,
    this.senderId,
    this.subject,
    this.content,
    this.isRead = false,
    this.category,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['sender_id'] as String?,
      subject: json['subject'] as String?,
      content: json['content'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'subject': subject,
      'content': content,
      'is_read': isRead,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
