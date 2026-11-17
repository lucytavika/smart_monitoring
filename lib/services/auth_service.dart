import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signOut();

      // 1. Proses Autentikasi Utama Supabase Auth
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final userId = res.user!.id;
        final authEmail = (res.user!.email ?? email).trim().toLowerCase();
        
        // Tentukan role dalam huruf kecil agar seragam dengan navigasi
        String detectedRole = (authEmail == 'admin@gmail.com') ? 'admin' : 'operator';

        // 2. Sinkronisasi tabel profiles
        try {
          final existingProfile = await _supabase
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

          if (existingProfile == null) {
            await _supabase.from('profiles').insert({
              'id': userId,
              'email': authEmail,
              'role': detectedRole == 'admin' ? 'Admin' : 'Operator',
              'is_online': true,
            });
          } else {
            await _supabase
                .from('profiles')
                .update({
                  'is_online': true,
                  'role': detectedRole == 'admin' ? 'Admin' : 'Operator',
                })
                .eq('id', userId);
          }
        } catch (profileErr) {
          print('Info profiles: $profileErr');
        }

        // 3. Sinkronisasi status online ke tabel OPERATORS menggunakan ID Auth (UUID)
        try {
          print('Mengupdate status online untuk operator ID: $userId');

          await _supabase
              .from('operators')
              .update({
                'is_online': true,
                'last_seen': DateTime.now().toIso8601String(),
              })
              .eq('id', userId); // Update langsung berdasarkan UUID yang sedang login

          print('Status online operator berhasil diupdate ke TRUE.');
        } catch (opErr) {
          print('=== ERROR SAAT UPDATE OPERATORS ===: $opErr');
        }

        return detectedRole;
      }
      return null;
    } catch (e) {
      print('====================================');
      print('DETAIL ERROR SUPABASE AUTH: $e');
      print('====================================');
      throw Exception(e.toString());
    }
  }
}