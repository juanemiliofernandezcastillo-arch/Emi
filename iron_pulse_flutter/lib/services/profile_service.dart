import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<String?> uploadAvatar(String userId, XFile imageFile) async {
    try {
      final fileExt = imageFile.name.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      
      // We read as bytes to support Flutter web as well (since the user is testing on chrome)
      final bytes = await imageFile.readAsBytes();
      
      await _client.storage.from('avatars').uploadBinary(
        fileName, 
        bytes,
        fileOptions: FileOptions(contentType: 'image/$fileExt'),
      );
      
      final imageUrl = _client.storage.from('avatars').getPublicUrl(fileName);
      
      // Update the profile
      await _client
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);
          
      return imageUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }
}
