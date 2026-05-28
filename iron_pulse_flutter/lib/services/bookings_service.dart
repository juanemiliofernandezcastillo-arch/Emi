import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

class BookingsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Booking?> getUserBookingForSchedule(String userId, String scheduleId) async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .eq('schedule_id', scheduleId)
          .maybeSingle();
      if (response == null) return null;
      return Booking.fromJson(response);
    } catch (e) {
      print('Error getting user booking: $e');
      return null;
    }
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('''
            *,
            class_schedules (
              *,
              classes (*),
              profiles (*)
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Booking.fromJson(e)).toList();
    } catch (e) {
      print('Error getting user bookings: $e');
      return [];
    }
  }

  Future<Booking?> reserveClass(String userId, ClassSchedule schedule) async {
    try {
      // Verificar si ya tiene reserva
      final existing = await getUserBookingForSchedule(userId, schedule.id);
      if (existing != null && existing.status != BookingStatus.cancelled) {
        throw Exception('User already has an active booking for this class.');
      }

      // Obtener conteo actual de reservas confirmadas
      final countResponse = await _client
          .from('bookings')
          .select('id')
          .eq('schedule_id', schedule.id)
          .eq('status', 'confirmed')
          .count(CountOption.exact);
          
      final confirmedCount = countResponse.count ?? 0;
      final availableSpots = schedule.capacity - confirmedCount;
      
      final newStatus = availableSpots > 0 ? 'confirmed' : 'waitlist';

      // Crear reserva (upsert en caso de que esté cancelada)
      final response = await _client.from('bookings').upsert({
        if (existing != null) 'id': existing.id,
        'user_id': userId,
        'schedule_id': schedule.id,
        'status': newStatus,
        'is_present': false,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, schedule_id').select().single();

      return Booking.fromJson(response);
    } catch (e) {
      print('Error reserving class: $e');
      return null;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    try {
      await _client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  Future<bool> markPresence(String bookingId, bool isPresent) async {
    try {
      await _client
          .from('bookings')
          .update({'is_present': isPresent})
          .eq('id', bookingId);
      return true;
    } catch (e) {
      print('Error marking presence: $e');
      return false;
    }
  }

  // --- Admin Methods ---

  Future<Map<String, dynamic>> getInstructorDashboardMetrics(String instructorId) async {
    try {
      final nowLocal = DateTime.now();
      final startOfDayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
      final endOfDayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, 23, 59, 59, 999);
      
      final startOfDayStr = startOfDayLocal.toUtc().toIso8601String();
      final endOfDayStr = endOfDayLocal.toUtc().toIso8601String();

      // Schedules today
      final schedulesResponse = await _client
          .from('class_schedules')
          .select('id, capacity')
          .eq('instructor_id', instructorId)
          .gte('start_time', startOfDayStr)
          .lte('start_time', endOfDayStr);

      int totalCapacity = 0;
      List<String> scheduleIds = [];
      for (var s in schedulesResponse as List) {
        totalCapacity += (s['capacity'] as int? ?? 0);
        scheduleIds.add(s['id'] as String);
      }

      int totalStudents = 0;
      double occupancyRate = 0.0;

      if (scheduleIds.isNotEmpty) {
        final bookings = await _client
            .from('bookings')
            .select('status')
            .inFilter('schedule_id', scheduleIds)
            .eq('status', 'confirmed');
        
        totalStudents = (bookings as List).length;
        occupancyRate = totalCapacity > 0 ? (totalStudents / totalCapacity) * 100 : 0.0;
      }

      return {
        'scheduled_classes_today': scheduleIds.length,
        'total_students_today': totalStudents,
        'occupancy_rate': occupancyRate,
      };

    } catch (e) {
      print('Error getting instructor dashboard metrics: $e');
      return {
        'scheduled_classes_today': 0,
        'total_students_today': 0,
        'occupancy_rate': 0.0,
      };
    }
  }

  Future<List<Booking>> getBookingsForSchedule(String scheduleId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, profiles(*)')
          .eq('schedule_id', scheduleId)
          .order('created_at', ascending: true);
          
      return (response as List).map((e) => Booking.fromJson(e)).toList();
    } catch (e) {
      print('Error getting bookings for schedule: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getTodayMetrics() async {
    try {
      final todayStart = DateTime.now().copyWith(hour: 0, minute: 0, second: 0).toIso8601String();
      final todayEnd = DateTime.now().copyWith(hour: 23, minute: 59, second: 59).toIso8601String();

      // 1. Clases de hoy
      final schedules = await _client
          .from('class_schedules')
          .select()
          .gte('start_time', todayStart)
          .lte('start_time', todayEnd);

      int totalCapacity = 0;
      List<String> scheduleIds = [];
      for (var s in schedules as List) {
        totalCapacity += (s['capacity'] as int? ?? 0);
        scheduleIds.add(s['id'] as String);
      }

      if (scheduleIds.isEmpty) {
        return {
          'confirmed': 0,
          'waitlist': 0,
          'occupancy_rate': 0.0,
          'happening_now': 0,
        };
      }

      // 2. Bookings de hoy
      final bookings = await _client
          .from('bookings')
          .select('status')
          .inFilter('schedule_id', scheduleIds);

      int confirmed = 0;
      int waitlist = 0;

      for (var b in bookings as List) {
        if (b['status'] == 'confirmed') confirmed++;
        if (b['status'] == 'waitlist') waitlist++;
      }

      double occupancyRate = totalCapacity > 0 ? (confirmed / totalCapacity) * 100 : 0.0;

      // 3. Happening now
      final nowStr = DateTime.now().toIso8601String();
      final happeningNowResponse = await _client
          .from('class_schedules')
          .select('id')
          .lte('start_time', nowStr)
          .gte('end_time', nowStr);
          
      int happeningNow = (happeningNowResponse as List).length;

      return {
        'confirmed': confirmed,
        'waitlist': waitlist,
        'occupancy_rate': occupancyRate,
        'happening_now': happeningNow,
      };
    } catch (e) {
      print('Error getting metrics: $e');
      return {
        'confirmed': 0,
        'waitlist': 0,
        'occupancy_rate': 0.0,
        'happening_now': 0,
      };
    }
  }

  Future<int> getTotalScheduledClasses() async {
    try {
      final response = await _client
          .from('class_schedules')
          .select('id')
          .count(CountOption.exact);
      return response.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getTodayScheduledClassesCount() async {
    try {
      final nowLocal = DateTime.now();
      final startOfDayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
      final endOfDayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, 23, 59, 59, 999);
      
      final nowStr = nowLocal.toUtc().toIso8601String();
      final startOfDayStr = startOfDayLocal.toUtc().toIso8601String();
      final endOfDayStr = endOfDayLocal.toUtc().toIso8601String();

      print('DEBUG-VIGENTES: now local = $nowLocal');
      print('DEBUG-VIGENTES: nowStr = $nowStr');
      print('DEBUG-VIGENTES: startOfDayStr = $startOfDayStr');
      print('DEBUG-VIGENTES: endOfDayStr = $endOfDayStr');

      final response = await _client
          .from('class_schedules')
          .select('id, start_time, end_time')
          .gte('start_time', startOfDayStr)
          .lte('start_time', endOfDayStr)
          .gte('end_time', nowStr);

      final list = response as List;
      final schedulesData = list.map((e) => 'start: ${e['start_time']}, end: ${e['end_time']}').toList();
      print('DEBUG-VIGENTES: clases encontradas = $schedulesData');
      print('DEBUG-VIGENTES: cantidad final = ${list.length}');

      return list.length;
    } catch (e) {
      print('Error en getTodayScheduledClassesCount: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> getAdminDashboardMetrics() async {
    try {
      final nowLocal = DateTime.now();
      final startOfDayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
      final endOfDayLocal = DateTime(nowLocal.year, nowLocal.month, nowLocal.day, 23, 59, 59, 999);
      
      final nowStr = nowLocal.toUtc().toIso8601String();
      final startOfDayStr = startOfDayLocal.toUtc().toIso8601String();
      final endOfDayStr = endOfDayLocal.toUtc().toIso8601String();

      // 1. Get Totals using the specific methods
      final int totalScheduledClasses = await getTotalScheduledClasses();
      print('DEBUG: totalScheduledClasses = $totalScheduledClasses');
      final int scheduledClassesToday = await getTodayScheduledClassesCount();
      print('DEBUG: vigentesClassesToday = $scheduledClassesToday');

      // 2. Scheduled Classes Today (get data for occupancy calculation)
      // Modificado para usar solo las VIGENTES de hoy y reflejar la Tasa de Ocupación real
      final schedulesResponse = await _client
          .from('class_schedules')
          .select('id, capacity, start_time, end_time')
          .gte('start_time', startOfDayStr)
          .lte('start_time', endOfDayStr)
          .gte('end_time', nowStr);

      int totalCapacity = 0;
      List<String> scheduleIds = [];
      for (var s in schedulesResponse as List) {
        totalCapacity += (s['capacity'] as int? ?? 0);
        scheduleIds.add(s['id'] as String);
      }

      double occupancyRate = 0.0;

      if (scheduleIds.isNotEmpty) {
        final bookings = await _client
            .from('bookings')
            .select('status')
            .inFilter('schedule_id', scheduleIds)
            .eq('status', 'confirmed');
        
        int confirmed = (bookings as List).length;
        occupancyRate = totalCapacity > 0 ? (confirmed / totalCapacity) * 100 : 0.0;
      }

      // 2. Total Students
      final studentsResponse = await _client
          .from('profiles')
          .select('id')
          .eq('role', 'client')
          .count(CountOption.exact);
      int totalStudents = studentsResponse.count ?? 0;

      // 3. Active Types (Categories)
      final categoriesResponse = await _client
          .from('categories')
          .select('id')
          .count(CountOption.exact);
      int activeTypes = categoriesResponse.count ?? 0;

      // 4. Happening Now or Next Upcoming
      final nowStrSingle = DateTime.now().toUtc().toIso8601String();
      // Try to find one happening right now
      var liveClassResponse = await _client
          .from('class_schedules')
          .select('*, classes(*), profiles(*)')
          .lte('start_time', nowStrSingle)
          .gte('end_time', nowStrSingle)
          .maybeSingle();

      if (liveClassResponse == null) {
        // Find next upcoming globally (no lte todayEnd so we catch 2026 dates)
        liveClassResponse = await _client
            .from('class_schedules')
            .select('*, classes(*), profiles(*)')
            .gte('start_time', nowStrSingle)
            .order('start_time', ascending: true)
            .limit(1)
            .maybeSingle();
      }

      ClassSchedule? happeningNowClass;
      int happeningNowBooked = 0;

      if (liveClassResponse != null) {
        happeningNowClass = ClassSchedule.fromJson(liveClassResponse);
        final countResponse = await _client
            .from('bookings')
            .select('id')
            .eq('schedule_id', happeningNowClass.id)
            .eq('status', 'confirmed')
            .count(CountOption.exact);
        happeningNowBooked = countResponse.count ?? 0;
      }

      return {
        'scheduled_classes_total': totalScheduledClasses,
        'scheduled_classes_today': scheduledClassesToday,
        'occupancy_rate': occupancyRate,
        'total_students': totalStudents,
        'happening_now_class': happeningNowClass,
        'happening_now_booked': happeningNowBooked,
      };

    } catch (e) {
      print('Error getting admin dashboard metrics: $e');
      return {
        'scheduled_classes_total': 0,
        'scheduled_classes_today': 0,
        'occupancy_rate': 0.0,
        'total_students': 0,
        'happening_now_class': null,
        'happening_now_booked': 0,
      };
    }
  }
}
