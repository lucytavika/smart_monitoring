import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String userRole; // 'admin' atau 'operator'

  const ProfileScreen({super.key, required this.userRole});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  String _nama = 'Memuat...';
  String _nomorId = '-';
  String _email = 'Memuat...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final session = supabase.auth.currentSession;
      final authEmail = session?.user.email ?? '-';
      final userId = session?.user.id;

      if (widget.userRole.toLowerCase() == 'admin') {
        if (mounted) {
          setState(() {
            _nama = 'Administrator';
            _nomorId = 'ADM-01';
            _email = authEmail;
            _isLoading = false;
          });
        }
      } else {
        Map<String, dynamic>? response;

        if (userId != null) {
          response = await supabase
              .from('operators')
              .select('nama, nomor_id, email')
              .eq('id', userId)
              .maybeSingle();
        }

        if (response == null && authEmail != '-') {
          response = await supabase
              .from('operators')
              .select('nama, nomor_id, email')
              .eq('email', authEmail)
              .maybeSingle();
        }

        if (mounted) {
          setState(() {
            _nama = response?['nama'] ?? '-';
            _nomorId = response?['nomor_id'] ?? '-';
            _email = response?['email'] ?? authEmail;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final fallbackEmail = supabase.auth.currentSession?.user.email ?? '-';
        setState(() {
          _nama = widget.userRole.toLowerCase() == 'admin' ? 'Administrator' : '-';
          _nomorId = '-';
          _email = fallbackEmail;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.userRole.toLowerCase() == 'admin';
    final String hakAksesText = isAdmin
        ? 'Supervisory, Management & Security Control'
        : 'Monitoring Data Sensor & Operasional Lapangan';

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'Profil Akun',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
                color: const Color(0xFFFFD700).withValues(alpha: 0.06),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.07),
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
                color: const Color(0xFF06B6D4).withValues(alpha: 0.08),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    blurRadius: 180,
                    spreadRadius: 90,
                  )
                ],
              ),
            ),
          ),

          // 5. Konten Profil Utama di Tengah
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Lingkaran Avatar / Logo dengan Glow Halus
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                          color: const Color(0xFF0F172A),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama atau Email Utama
                    _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isAdmin ? _email : _nama,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                    const SizedBox(height: 8),

                    // Badge / Subtitle Role
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isAdmin ? 'Smart Motor Monitoring' : 'ID Operator: $_nomorId',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Kartu Glassmorphism Informasi Akun
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B192C).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 35,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (!isAdmin) ...[
                            _buildProfileRow(
                              icon: Icons.person_outline_rounded,
                              title: 'Nama Operator',
                              value: _isLoading ? 'Memuat...' : _nama,
                            ),
                            const Divider(color: Colors.white12, height: 28),
                            _buildProfileRow(
                              icon: Icons.badge_outlined,
                              title: 'ID Operator',
                              value: _isLoading ? 'Memuat...' : _nomorId,
                            ),
                            const Divider(color: Colors.white12, height: 28),
                          ],
                          _buildProfileRow(
                            icon: Icons.mail_outline_rounded,
                            title: 'Email Login',
                            value: _isLoading ? 'Memuat...' : _email,
                          ),
                          const Divider(color: Colors.white12, height: 28),
                          _buildProfileRow(
                            icon: Icons.security_rounded,
                            title: 'Hak Akses',
                            value: hakAksesText,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Tombol Logout dengan Gradasi Merah Modern
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            print('=== TOMBOL LOGOUT BERHASIL DIKLIK! ===');

                            final session = supabase.auth.currentSession;
                            final userEmail = session?.user.email ?? _email;

                            try {
                              final cleanEmail = userEmail.trim().toLowerCase();
                              if (cleanEmail.isNotEmpty && cleanEmail != 'memuat...' && cleanEmail != '-') {
                                await supabase.rpc('set_operator_offline_by_email', params: {
                                  'operator_email': cleanEmail,
                                });
                                print('Status offline via RPC BERHASIL dikirim ke server.');
                                await Future.delayed(const Duration(milliseconds: 500));
                              }
                            } catch (e) {
                              print('GAGAL RPC: $e');
                            }

                            try {
                              await supabase.auth.signOut();
                              print('Sign out Auth BERHASIL.');
                            } catch (e) {
                              print('Error signOut: $e');
                            }

                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                          label: const Text(
                            'LOGOUT',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
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

  Widget _buildProfileRow({required IconData icon, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF040F1E).withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, color: const Color(0xFFFFD700), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Custom Painter Latar Belakang Estetik
class AestheticTechBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;

    const gridSize = 56.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final tracePaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final nodeFill = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.3)
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
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 320, ringPaint);
    canvas.drawCircle(center, 440, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}