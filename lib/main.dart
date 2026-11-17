import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_monitoring/screens/login_screen.dart';
import 'package:smart_monitoring/screens/dashboard_screen.dart';
import 'package:smart_monitoring/screens/grafik_screen.dart'; 
import 'package:smart_monitoring/screens/riwayat_screen.dart';
import 'package:smart_monitoring/screens/profile_screen.dart';
import 'package:smart_monitoring/screens/signup_operator_screen.dart';
import 'package:smart_monitoring/screens/operator_list_screen.dart';
import 'package:smart_monitoring/services/mqtt_service.dart';
import 'package:smart_monitoring/services/notification_service.dart'; // Import service notifikasi lokal

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Layanan Notifikasi Lokal/Sistem HP
  await NotificationService.init();

  await Supabase.initialize(
    url: 'https://irqvoqevvuowcdhjlpmn.supabase.co',
    anonKey: 'sb_publishable_5gYJvgm77bWHr8vFDegjZw_3nWMtx_p', 
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Motor Monitoring',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent, 
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7CF6), // Disesuaikan dengan warna tema terang
          elevation: 0,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main_navigation': (context) => const MainNavigation(),
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late MqttService _mqttService;
  String userRole = 'Operator';

  @override
  void initState() {
    super.initState();
    final String uniqueId = 'flutter_kel4_${Random().nextInt(9999)}';
    _mqttService = MqttService(clientId: uniqueId);
    _mqttService.connect();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is String) {
      userRole = args;
    }
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = userRole.toUpperCase() == 'ADMIN';
    final formattedRole = userRole.isNotEmpty 
        ? userRole[0].toUpperCase() + userRole.substring(1) 
        : 'User';

    final List<Widget> screens = [
      DashboardScreen(mqttService: _mqttService, userRole: userRole),
      GrafikScreen(mqttService: _mqttService, userRole: userRole), 
      RiwayatScreen(mqttService: _mqttService, userRole: userRole),
      if (isAdmin) SignupOperatorScreen(userRole: userRole),
      if (isAdmin) OperatorListScreen(userRole: userRole),
    ];

    return Scaffold(
      extendBody: true, // Agar gradasi background tembus ke bawah di belakang navbar
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Smart Motor Monitoring',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(userRole: userRole),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 16, color: Color(0xFF2E7CF6)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedRole,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      // BACKGROUND UTAMA: Gradasi Biru Cerah ke Putih Bersih (Menyeluruh)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7CF6), // Biru cerah di bagian atas
              Color(0xFF8AC1F9), // Biru muda di bagian tengah
              Color(0xFFF4F7FC), // Putih kebiruan cerah di bagian bawah
            ],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentIndex >= screens.length ? 0 : _currentIndex,
            children: screens,
          ),
        ),
      ),
      // BOTTOM NAVIGATION BAR MELAYANG (FLOATING STYLE)
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.dashboard_rounded, 'Dashboard', 0),
            _buildNavItem(Icons.bar_chart_rounded, 'Grafik', 1),
            _buildNavItem(Icons.history_rounded, 'Riwayat', 2),
            if (isAdmin) _buildNavItem(Icons.person_add_rounded, 'Daftar', 3),
            if (isAdmin) _buildNavItem(Icons.group_rounded, 'Operator', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool active = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: active ? 14 : 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2E7CF6).withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? const Color(0xFF2E7CF6) : Colors.grey.shade400,
              size: 22,
            ),
            if (active) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2E7CF6),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}