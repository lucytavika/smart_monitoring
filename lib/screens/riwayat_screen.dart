import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_monitoring/services/mqtt_service.dart';
import 'package:smart_monitoring/models/sensor_model.dart';

class RiwayatScreen extends StatefulWidget {
  final MqttService mqttService;
  final String userRole;

  const RiwayatScreen({super.key, required this.mqttService, required this.userRole});

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  String _evaluateSuhu(double val) {
    if (val >= 60.0) return 'Bahaya';
    if (val >= 40.0) return 'Waspada';
    return 'Normal';
  }

  String _evaluateGetaran(double val) {
    if (val >= 2.50) return 'Bahaya';
    if (val >= 1.50) return 'Waspada';
    return 'Normal';
  }

  String _evaluateSuara(double val) {
    if (val >= 2.50) return 'Bahaya';
    if (val >= 2.0) return 'Waspada';
    return 'Normal';
  }

  String _calculateRealStatus(double suhu, double getaran, double suara) {
    String sSuhu = _evaluateSuhu(suhu);
    String sGetaran = _evaluateGetaran(getaran);
    String sSuara = _evaluateSuara(suara);

    if (sSuhu == 'Bahaya' || sGetaran == 'Bahaya' || sSuara == 'Bahaya') {
      return 'Bahaya';
    } else if (sSuhu == 'Waspada' || sGetaran == 'Waspada' || sSuara == 'Waspada') {
      return 'Waspada';
    }
    return 'Normal';
  }

  String _formatWaktuWIB(String? createdAtStr) {
    if (createdAtStr == null || createdAtStr.isEmpty) return '-';
    try {
      DateTime? parsedDate = DateTime.tryParse(createdAtStr);
      if (parsedDate == null) return createdAtStr;

      DateTime wibTime = parsedDate.toLocal();
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      return '${wibTime.year}-${twoDigits(wibTime.month)}-${twoDigits(wibTime.day)} ${twoDigits(wibTime.hour)}:${twoDigits(wibTime.minute)}:${twoDigits(wibTime.second)} WIB';
    } catch (_) {
      return createdAtStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'BAHAYA':
        return Colors.red.shade700;
      case 'WASPADA':
        return Colors.amber.shade800;
      case 'NORMAL':
      default:
        return Colors.green.shade700;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'BAHAYA':
        return Icons.error_outline;
      case 'WASPADA':
        return Icons.warning_amber_rounded;
      case 'NORMAL':
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Perubahan Kondisi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF2E7CF6)),
                    onPressed: () => setState(() {}),
                    tooltip: 'Muat Ulang',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<SensorModel?>(
                valueListenable: widget.mqttService.sensorDataNotifier,
                builder: (context, liveData, child) {
                  return FutureBuilder<List>(
                    future: supabase
                        .from('riwayat_pengukuran')
                        .select()
                        .order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7CF6)));
                      }

                      List rawList = [];
                      if (snapshot.hasData) {
                        rawList = List.from(snapshot.data!);
                      }

                      if (liveData != null) {
                        rawList.insert(0, {
                          'id': 'live_${DateTime.now().millisecondsSinceEpoch}',
                          'suhu': liveData.suhu,
                          'getaran': liveData.getaran,
                          'suara': liveData.suara,
                          'created_at': DateTime.now().toIso8601String(),
                        });
                      }

                      DateTime now = DateTime.now();
                      List filteredList = [];

                      for (var item in rawList) {
                        String createdAtStr = item['created_at'] ?? '';
                        DateTime? itemTime = DateTime.tryParse(createdAtStr);

                        if (itemTime != null) {
                          DateTime localTime = itemTime.toLocal();
                          Duration selisih = now.difference(localTime);

                          if (selisih.inHours < 24 && !selisih.isNegative) {
                            filteredList.add(item);
                          }
                        }
                      }

                      if (filteredList.isEmpty) {
                        return const Center(
                          child: Text('Belum ada riwayat pengukuran dalam 24 jam terakhir.', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final log = filteredList[index];
                          double suhu = (log['suhu'] as num?)?.toDouble() ?? 0.0;
                          double getaran = (log['getaran'] as num?)?.toDouble() ?? 0.0;
                          double suara = (log['suara'] as num?)?.toDouble() ?? 0.0;

                          String status = _calculateRealStatus(suhu, getaran, suara);
                          Color statusColor = _getStatusColor(status);
                          String formattedTime = _formatWaktuWIB(log['created_at']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  color: statusColor,
                                  size: 28,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status: ${status.toUpperCase()}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: statusColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Perubahan satuan: Getaran jadi m/s², Suara jadi dB
                                      Text(
                                        'Suhu: ${suhu.toStringAsFixed(1)}°C | Getaran: ${getaran.toStringAsFixed(2)} m/s² | Suara: ${suara.toStringAsFixed(2)} dB',
                                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Waktu: $formattedTime',
                                        style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}