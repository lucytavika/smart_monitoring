import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF070B19);
  static const Color cardBackground = Color(0xFF101935);
  
  // GRADASI BACKGROUND UTAMA YANG DINAMIS & ELEGAN
  static const LinearGradient industrialBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0B132B), // Biru gelap berkarakter di atas
      Color(0xFF070B19), // Hitam kebiruan di tengah
      Color(0xFF03050C), // Hitam pekat industrial di bagian bawah
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF14213D),
      Color(0xFF0F172A),
    ],
  );
}