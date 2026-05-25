import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

class MessagesService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Message>> getUserMessages(String userId) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('sender_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      print('Error getting user messages: $e');
      return [];
    }
  }

  Future<List<Message>> getAllMessages({String? category}) async {
    try {
      var query = _client.from('messages').select('*, profiles(*)');
      
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }
      
      final response = await query.order('created_at', ascending: false);
      return (response as List).map((e) => Message.fromJson(e)).toList();
    } catch (e) {
      print('Error getting all messages: $e');
      return [];
    }
  }

  Future<bool> markAsRead(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('id', messageId);
      return true;
    } catch (e) {
      print('Error marking message as read: $e');
      return false;
    }
  }
}
