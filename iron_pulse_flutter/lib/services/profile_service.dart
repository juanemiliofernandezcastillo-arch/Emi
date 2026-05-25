import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<Profile?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return Profile.fromJson(response);
  }

  Future<Profile> updateProfile(Profile profile) async {
    final response = await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();
        
    return Profile.fromJson(response);
  }
}
