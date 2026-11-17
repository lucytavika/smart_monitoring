import 'package:flutter/material.dart';
import 'package:smart_monitoring/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final SupabaseClient supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password tidak boleh kosong'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Proses login menggunakan auth service
      String? detectedRole = await _authService.loginUser(
        email: email,
        password: password,
      );

      if (detectedRole != null) {
        // 2. AMBIL USER ID YANG VALID DARI SESI SUPABASE AUTH
        final currentUserId = supabase.auth.currentUser?.id;

        if (currentUserId != null) {
          try {
            // Update status online menggunakan ID unik (UUID) agar 100% akurat
            await supabase
                .from('operators')
                .update({'is_online': true})
                .eq('id', currentUserId);
                
            debugPrint('Status operator berhasil diubah menjadi Online (TRUE) via ID: $currentUserId');
          } catch (updateErr) {
            debugPrint('Gagal memperbarui status online: $updateErr');
          }
        }

        if (!mounted) return;
        setState(() => _isLoading = false);

        Navigator.pushReplacementNamed(
          context,
          '/main_navigation',
          arguments: detectedRole,
        );
      }
    } catch (e) {
      print('DETAIL ERROR LOGIN: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login Gagal: Akun tidak ditemukan atau sandi salah'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Stack(
        children: [
          // 1. Background Gradasi Utama yang Kaya & Dalam
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Slate Dark
                  Color(0xFF0A1931), // Deep Blue Industrial
                  Color(0xFF020617), // Midnight Black-Blue
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // 2. Custom Painter untuk Pola Sirkuit & Estetika Grid Modern
          Positioned.fill(
            child: CustomPaint(
              painter: AestheticTechBackgroundPainter(),
            ),
          ),

          // 3. Efek Cahaya / Glow Ambient Emas/Amber di Kanan Atas
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 480,
              height: 480,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700).withOpacity(0.06),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.07),
                    blurRadius: 200,
                    spreadRadius: 100,
                  )
                ],
              ),
            ),
          ),

          // 4. Efek Pendar Cahaya Cyan/Biru Futuristik di Kiri Bawah
          Positioned(
            bottom: -140,
            left: -120,
            child: Container(
              width: 460,
              height: 460,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    blurRadius: 180,
                    spreadRadius: 90,
                  )
                ],
              ),
            ),
          ),

          // 5. Kotak Form Login Utama di Tengah
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Bulat dengan Glow Halus
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.precision_manufacturing_rounded,
                          color: Color(0xFF0F172A),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Judul Aplikasi
                    const Text(
                      'Smart Motor Monitoring',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Satu sistem untuk manajemen & kendali industri',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Kartu Form Glassmorphism Estetik
                    Container(
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B192C).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.45),
                            blurRadius: 35,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Akses akun',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masuk untuk mengatur dan memantau sistem.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Input Email
                          Text(
                            'Email',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.mail_outline,
                                color: Colors.white.withOpacity(0.65),
                                size: 20,
                              ),
                              hintText: 'Contoh: admin@gmail.com',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF040F1E).withOpacity(0.85),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFD700),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Input Password
                          Text(
                            'Password',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onSubmitted: (_) => _signIn(),
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: Colors.white.withOpacity(0.65),
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.white.withOpacity(0.65),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              hintText: 'Masukkan password',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF040F1E).withOpacity(0.85),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFFFD700),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Tombol Masuk Sistem
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFFFD700),
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0xFF2563EB),
                                          Color(0xFF06B6D4),
                                          Color(0xFFFFD700),
                                        ],
                                        stops: [0.0, 0.6, 1.0],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB).withOpacity(0.4),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: _signIn,
                                      child: const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Footer Informasi
                    Text(
                      'ALURASA',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'v2.1.0 (20261114)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter Latar Belakang Estetik
class AestheticTechBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    const gridSize = 56.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final tracePaint = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final nodeFill = Paint()
      ..color = const Color(0xFF06B6D4).withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final pathTL = Path()
      ..moveTo(0, size.height * 0.18)
      ..lineTo(size.width * 0.12, size.height * 0.18)
      ..lineTo(size.width * 0.2, size.height * 0.1)
      ..lineTo(size.width * 0.32, size.height * 0.1);
    canvas.drawPath(pathTL, tracePaint);
    canvas.drawCircle(Offset(size.width * 0.32, size.height * 0.1), 3.5, nodeFill);

    final pathBL = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width * 0.16, size.height * 0.82)
      ..lineTo(size.width * 0.24, size.height * 0.9)
      ..lineTo(size.width * 0.38, size.height * 0.9);
    canvas.drawPath(pathBL, tracePaint);
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.9), 3.5, nodeFill);

    final pathTR = Path()
      ..moveTo(size.width, size.height * 0.22)
      ..lineTo(size.width * 0.85, size.height * 0.22)
      ..lineTo(size.width * 0.77, size.height * 0.32)
      ..lineTo(size.width * 0.62, size.height * 0.32);
    canvas.drawPath(pathTR, tracePaint);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.32), 3.5, nodeFill);

    final pathBR = Path()
      ..moveTo(size.width, size.height * 0.78)
      ..lineTo(size.width * 0.82, size.height * 0.78)
      ..lineTo(size.width * 0.74, size.height * 0.68)
      ..lineTo(size.width * 0.6, size.height * 0.68);
    canvas.drawPath(pathBR, tracePaint);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.68), 3.5, nodeFill);

    final ringPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 320, ringPaint);
    canvas.drawCircle(center, 440, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}