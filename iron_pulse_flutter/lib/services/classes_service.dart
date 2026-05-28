import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

class ClassesService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Category>> getCategories() async {
    try {
      final response = await _client.from('categories').select();
      return (response as List).map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  Future<List<ClassSchedule>> getUpcomingSchedules({String? categoryId}) async {
    try {
      // Obtener todas las reservas agrupadas por schedule para calcular disponibilidad
      // Como Supabase RPC o vistas son mejores, aquí lo calculamos en dart o usamos la relación.
      // Suponemos que podemos contar desde flutter si la tabla no es gigante, o lo resolvemos uniendo datos.
      
      var query = _client.from('class_schedules').select('''
        *,
        classes!inner(*),
        profiles(*)
      ''').gte('start_time', DateTime.now().toIso8601String());
      
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('classes.category_id', categoryId);
      }

      final response = await query.order('start_time', ascending: true);
      
      // Obtener el conteo de reservas confirmadas para cada clase
      // Para optimizar en producción, se recomienda una vista (view) en Supabase
      List<ClassSchedule> schedules = [];
      for (var row in response as List) {
        final countResponse = await _client
            .from('bookings')
            .select('id')
            .eq('schedule_id', row['id'])
            .eq('status', 'confirmed')
            .count(CountOption.exact);
            
        row['booked_count'] = countResponse.count ?? 0;
        schedules.add(ClassSchedule.fromJson(row));
      }
      return schedules;
    } catch (e) {
      print('Error getting schedules: $e');
      return [];
    }
  }
  
  Future<List<ClassSchedule>> getInstructorSchedules(String instructorId) async {
    try {
      var query = _client.from('class_schedules').select('''
        *,
        classes!inner(*),
        profiles(*)
      ''').eq('instructor_id', instructorId).gte('start_time', DateTime.now().toIso8601String()).order('start_time', ascending: true);
      
      final response = await query;
      
      List<ClassSchedule> schedules = [];
      for (var row in response as List) {
        final countResponse = await _client
            .from('bookings')
            .select('id')
            .eq('schedule_id', row['id'])
            .eq('status', 'confirmed')
            .count(CountOption.exact);
            
        row['booked_count'] = countResponse.count ?? 0;
        schedules.add(ClassSchedule.fromJson(row));
      }
      return schedules;
    } catch (e) {
      print('Error getting instructor schedules: $e');
      return [];
    }
  }
  
  Future<ClassSchedule?> getScheduleDetails(String scheduleId) async {
    try {
      final response = await _client.from('class_schedules').select('''
        *,
        classes(*),
        profiles(*)
      ''').eq('id', scheduleId).maybeSingle();
      
      if (response == null) return null;
      
      final countResponse = await _client
          .from('bookings')
          .select('id')
          .eq('schedule_id', scheduleId)
          .eq('status', 'confirmed')
          .count(CountOption.exact);
          
      response['booked_count'] = countResponse.count ?? 0;
      return ClassSchedule.fromJson(response);
    } catch (e) {
      print('Error getting schedule detail: $e');
      return null;
    }
  }

  Future<List<Profile>> getInstructors() async {
    try {
      final response = await _client.from('profiles').select().eq('role', 'instructor');
      return (response as List).map((e) => Profile.fromJson(e)).toList();
    } catch (e) {
      print('Error getting instructors: $e');
      return [];
    }
  }

  Future<Instructor?> getInstructorDetailsByName(String name) async {
    try {
      final response = await _client.from('instructors').select().ilike('name', '%$name%').maybeSingle();
      if (response != null) {
        return Instructor.fromJson(response);
      }
      
      // Fallback: get any instructor to show the UI
      final fallback = await _client.from('instructors').select().limit(1).maybeSingle();
      if (fallback != null) {
        return Instructor.fromJson(fallback);
      }
      return null;
    } catch (e) {
      print('Error getting instructor details: $e');
      return null;
    }
  }

  Future<List<ClassModel>> getClasses() async {
    try {
      final response = await _client.from('classes').select().order('name');
      return (response as List).map((e) => ClassModel.fromJson(e)).toList();
    } catch (e) {
      print('Error getting classes: $e');
      return [];
    }
  }

  Future<ClassModel> createClass(ClassModel classModel) async {
    final data = classModel.toJson();
    data.remove('id'); // ID is autogenerated
    final response = await _client.from('classes').insert(data).select().single();
    return ClassModel.fromJson(response);
  }

  Future<ClassModel> updateClass(ClassModel classModel) async {
    final data = classModel.toJson();
    final response = await _client.from('classes').update(data).eq('id', classModel.id).select().single();
    return ClassModel.fromJson(response);
  }

  Future<ClassSchedule> createSchedule(ClassSchedule schedule) async {
    final data = schedule.toJson();
    data.remove('id');
    final response = await _client.from('class_schedules').insert(data).select().single();
    return ClassSchedule.fromJson(response);
  }

  Future<ClassSchedule> updateSchedule(ClassSchedule schedule) async {
    final data = schedule.toJson();
    final response = await _client.from('class_schedules').update(data).eq('id', schedule.id).select().single();
    return ClassSchedule.fromJson(response);
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _client.from('class_schedules').delete().eq('id', scheduleId);
  }

  Future<String?> uploadClassImage(File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'classes/$fileName';

      await _client.storage.from('class-images').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl = _client.storage.from('class-images').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
