import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String sensorType;
  final String value;
  final String limit;
  final String labelStatus;
  final bool isDanger;

  const SensorCard({
    super.key,
    required this.title,
    required this.sensorType,
    required this.value,
    required this.limit,
    required this.labelStatus,
    required this.isDanger,
  });

  @override
  Widget build(BuildContext context) {
    // Penentuan warna badge status murni menggunakan Hex Color agar aman di browser web
    Color badgeColor = const Color(0xFF15803D); // Hijau (Normal)
    if (labelStatus == "Bahaya") badgeColor = const Color(0xFFB91C1C); // Merah
    if (labelStatus == "Waspada") badgeColor = const Color(0xFFC2410C); // Jingga
    if (labelStatus == "Error") badgeColor = const Color(0xFF78716C); // Abu-abu

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), 
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Mengembalikan distribusi ruang vertikal yang stabil
        children: [
          // 1. Bagian Judul dan Tipe Hardware Sensor
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title, 
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                sensorType, 
                style: const TextStyle(color: Colors.grey, fontSize: 11), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          
          // 2. Nilai Parameter Sensor Utama (Aman dari bug layout infinite bounds karena tanpa FittedBox)
          Text(
            value, 
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          
          // 3. Batas Ambang Nilai & Badge Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  limit, 
                  style: const TextStyle(color: Colors.grey, fontSize: 10), 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  labelStatus, 
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}