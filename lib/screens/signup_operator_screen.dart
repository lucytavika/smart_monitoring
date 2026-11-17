import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupOperatorScreen extends StatefulWidget {
  final String userRole;

  const SignupOperatorScreen({super.key, required this.userRole});

  @override
  State<SignupOperatorScreen> createState() => _SignupOperatorScreenState();
}

class _SignupOperatorScreenState extends State<SignupOperatorScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _idController = TextEditingController(); // Untuk nomor ID (misal: '01')
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _daftarOperator() async {
    final String nama = _namaController.text.trim();
    final String nomorId = _idController.text.trim(); // ID buatan Anda
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (nama.isEmpty || nomorId.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Simpan sesi admin sebelum mendaftarkan operator
      final adminSession = supabase.auth.currentSession;

      // 1. Daftarkan akun ke Supabase Auth untuk mendapatkan UUID resmi
      final AuthResponse res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final userId = res.user!.id;

        // 2. Simpan data ke tabel operators (menggunakan UUID auth sebagai primary key,
        // dan menyimpan nomor_id buatan Anda)
        await supabase.from('operators').insert({
          'id': userId,
          'nomor_id': nomorId,
          'nama': nama,
          'email': email,
          'password': password,
          'is_online': false,
        });

        // 3. Kembalikan sesi admin
        if (adminSession?.refreshToken != null) {
          await supabase.auth.setSession(adminSession!.refreshToken!);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun operator berhasil didaftarkan!')),
          );

          _namaController.clear();
          _idController.clear();
          _emailController.clear();
          _passwordController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendaftarkan operator: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Menyesuaikan dengan latar belakang gradasi utama
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pendaftaran Akun Operator Baru',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            const Text(
              'Masukkan data akun operator (Nama, ID, Email, Password).',
              style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Input Nama Lengkap
            TextField(
              controller: _namaController,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Nama Lengkap Operator',
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.person, color: Color(0xFF2E7CF6)),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7CF6), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input ID / Nomor Operator (Contoh: 01)
            TextField(
              controller: _idController,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'ID Operator (Contoh: 01)',
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.badge, color: Color(0xFF2E7CF6)),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7CF6), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input Email
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Email Login',
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.email, color: Color(0xFF2E7CF6)),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7CF6), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input Password
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: Colors.black54),
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF2E7CF6)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7CF6), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Daftarkan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7CF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _daftarOperator,
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'DAFTARKAN OPERATOR',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}