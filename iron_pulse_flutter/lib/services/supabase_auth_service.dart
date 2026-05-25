import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // Obtener el estado de autenticación como Stream
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // Obtener usuario actual
  User? get currentUser => _client.auth.currentUser;

  // Registro (SignUp)
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );
  }

  // Inicio de Sesión (SignIn)
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Inicio de Sesión OAuth (Google / Apple)
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider,
      redirectTo: 'io.supabase.ironpulse://login-callback',
    );
  }

  // Cerrar Sesión (SignOut)
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
