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
        instructors(*)
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
  
  Future<ClassSchedule?> getScheduleDetails(String scheduleId) async {
    try {
      final response = await _client.from('class_schedules').select('''
        *,
        classes(*),
        instructors(*)
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
}
