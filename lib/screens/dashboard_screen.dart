import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_monitoring/services/mqtt_service.dart';
import 'package:smart_monitoring/models/sensor_model.dart';
import 'package:smart_monitoring/services/notification_service.dart';
import 'package:vibration/vibration.dart';

class DashboardScreen extends StatefulWidget {
  final MqttService mqttService;
  final String userRole;

  const DashboardScreen({
    super.key,
    required this.mqttService,
    required this.userRole,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  
  bool _isAlertOpen = false;
  bool _isDismissedByManual = false;

  String _getStatusSuhu(double val) {
    if (val >= 60.0) return 'Bahaya';
    if (val >= 40.0) return 'Waspada';
    return 'Normal';
  }

  String _getStatusGetaran(double val) {
    if (val >= 2.50) return 'Bahaya';
    if (val >= 1.50) return 'Waspada';
    return 'Normal';
  }

  String _getStatusSuara(double val) {
    if (val >= 2.50) return 'Bahaya';
    if (val >= 2.0) return 'Waspada';
    return 'Normal';
  }

  Color _getColorByStatus(String status) {
    switch (status.toUpperCase()) {
      case 'BAHAYA':
        return Colors.redAccent;
      case 'WASPADA':
        return Colors.amber;
      default:
        return Colors.greenAccent;
    }
  }

  Color _getCardBackgroundColor(String status) {
    switch (status.toUpperCase()) {
      case 'BAHAYA':
        return const Color(0xFFFFCDD2);
      case 'WASPADA':
        return const Color(0xFFFFE082);
      case 'NORMAL':
      default:
        return const Color(0xFFC8E6C9);
    }
  }

  void _sendControlCommand(String command) {
    try {
      widget.mqttService.publish('motor/control', command);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perintah dikirim: Motor ${command == "ON" ? "DIHIDUPKAN (ON)" : "DIMATIKAN (OFF)"}'),
          backgroundColor: command == "ON" ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim perintah ke MQTT'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _triggerVibrationSafely() async {
    try {
      if (!kIsWeb) {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(pattern: [0, 500, 200, 500]);
        }
      }
    } catch (e) {
      debugPrint('Getar tidak didukung: $e');
    }
  }

  void _checkAndShowDangerAlert(String statusSistem, double suhu, double getaran, double suara, String statusSuhu, String statusGetaran, String statusSuara) {
    if (statusSistem == 'BAHAYA') {
      if (_isDismissedByManual) return;

      if (!_isAlertOpen && mounted) {
        _isAlertOpen = true;
        _triggerVibrationSafely();

        NotificationService.showDangerNotification(
          title: '🚨 PERINGATAN BAHAYA MESIN!',
          body: 'Suhu, getaran, atau suara melewati batas aman. Segera periksa sistem!',
        );

        List<String> pesanRekomendasi = [];
        if (statusSuhu.toUpperCase() == 'BAHAYA' || statusSuhu.toUpperCase() == 'WASPADA') {
          pesanRekomendasi.add('• Suhu motor melewati batas aman (>= 40°C), segera cek mechanical!');
        }
        if (statusGetaran.toUpperCase() == 'BAHAYA' || statusGetaran.toUpperCase() == 'WASPADA') {
          pesanRekomendasi.add('• Getaran melebihi batas normal (>= 1.50 m/s²), segera cek mechanical!');
        }
        if (statusSuara.toUpperCase() == 'BAHAYA' || statusSuara.toUpperCase() == 'WASPADA') {
          pesanRekomendasi.add('• Intensitas suara tinggi (>= 2.0 dB), periksa gesekan komponen!');
        }
        if (pesanRekomendasi.isEmpty) {
          pesanRekomendasi.add('• Segera lakukan pemeriksaan menyeluruh atau hentikan operasi motor!');
        }

        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Alert',
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (dialogContext, animation, secondaryAnimation) {
            return SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141E33),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'PERINGATAN BAHAYA!',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                                onPressed: () {
                                  _isDismissedByManual = true;
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sistem mendeteksi anomali kritis pada parameter berikut:',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF070B14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                _buildAlertRow('Suhu', '${suhu.toStringAsFixed(1)} °C', statusSuhu),
                                const Divider(color: Colors.white12, height: 8),
                                _buildAlertRow('Getaran', '${getaran.toStringAsFixed(2)} m/s²', statusGetaran),
                                const Divider(color: Colors.white12, height: 8),
                                _buildAlertRow('Suara', '${suara.toStringAsFixed(2)} dB', statusSuara),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: pesanRekomendasi
                                  .map((pesan) => Padding(
                                        padding: const EdgeInsets.only(bottom: 2.0),
                                        child: Text(
                                          pesan,
                                          style: const TextStyle(
                                            color: Colors.amberAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          transitionBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
        ).then((_) {
          _isAlertOpen = false;
        });
      }
    } else {
      _isDismissedByManual = false;

      if (_isAlertOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        _isAlertOpen = false;
      }
    }
  }

  Widget _buildAlertRow(String label, String value, String status) {
    Color statusColor = _getColorByStatus(status);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${status.toUpperCase()})',
              style: TextStyle(
                color: statusColor.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ValueListenableBuilder<SensorModel?>(
        valueListenable: widget.mqttService.sensorDataNotifier,
        builder: (context, sensorData, child) {
          if (sensorData == null) {
            return FutureBuilder<List>(
              future: supabase.from('riwayat_pengukuran').select().order('created_at', ascending: false).limit(1),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.hasError || snapshot.data!.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                final item = snapshot.data!.first;
                double s = (item['suhu'] as num?)?.toDouble() ?? 0.0;
                double g = (item['getaran'] as num?)?.toDouble() ?? 0.0;
                double su = (item['suara'] as num?)?.toDouble() ?? 0.0;

                String sSuhu = _getStatusSuhu(s);
                String sGetaran = _getStatusGetaran(g);
                String sSuara = _getStatusSuara(su);
                String sMotor = (sSuhu == 'Bahaya' || sGetaran == 'Bahaya' || sSuara == 'Bahaya')
                    ? 'BAHAYA'
                    : ((sSuhu == 'Waspada' || sGetaran == 'Waspada' || sSuara == 'Waspada') ? 'WASPADA' : 'NORMAL');

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkAndShowDangerAlert(sMotor, s, g, su, sSuhu, sGetaran, sSuara);
                });

                return _buildDashboardContent(s, g, su, sMotor);
              },
            );
          }

          double s = sensorData.suhu;
          double g = sensorData.getaran;
          double su = sensorData.suara;

          String sSuhu = _getStatusSuhu(s);
          String sGetaran = _getStatusGetaran(g);
          String sSuara = _getStatusSuara(su);
          String sMotor = (sSuhu == 'Bahaya' || sGetaran == 'Bahaya' || sSuara == 'Bahaya')
              ? 'BAHAYA'
              : ((sSuhu == 'Waspada' || sGetaran == 'Waspada' || sSuara == 'Waspada') ? 'WASPADA' : 'NORMAL');

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkAndShowDangerAlert(sMotor, s, g, su, sSuhu, sGetaran, sSuara);
          });

          return _buildDashboardContent(s, g, su, sMotor);
        },
      ),
    );
  }

  Widget _buildDashboardContent(double suhu, double getaran, double suara, String statusMotor) {
    String statusSuhu = _getStatusSuhu(suhu);
    String statusGetaran = _getStatusGetaran(getaran);
    String statusSuara = _getStatusSuara(suara);

    Color mainColor = _getColorByStatus(statusMotor);
    Color cardBgColor = _getCardBackgroundColor(statusMotor);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: mainColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: mainColor, size: 38),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Status Sistem (Real-time)', style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text(statusMotor, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: mainColor)),
                          ],
                        ),
                      ],
                    ),
                    Chip(
                      label: Text(statusMotor == 'BAHAYA' ? 'Buzzer ON' : 'Buzzer OFF'),
                      backgroundColor: statusMotor == 'BAHAYA' ? Colors.red.shade700 : Colors.green.shade700,
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  statusMotor == 'NORMAL' 
                      ? 'Semua parameter dalam kondisi ideal.' 
                      : 'Peringatan! Terdeteksi parameter melewati batas aman.',
                  style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('LED: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                    const SizedBox(width: 4),
                    _buildLedIndicator('Hijau', statusMotor == 'NORMAL', Colors.green.shade700),
                    _buildLedIndicator('Kuning', statusMotor == 'WASPADA', Colors.amber.shade900),
                    _buildLedIndicator('Merah', statusMotor == 'BAHAYA', Colors.red.shade700),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSensorProgressCard(
            title: 'Suhu · DS18B20',
            valueStr: '${suhu.toStringAsFixed(1)} °C',
            limitStr: 'Batas Normal < 40 °C',
            status: statusSuhu,
            pct: (suhu / 60.0).clamp(0.0, 1.0),
            icon: Icons.thermostat,
          ),
          const SizedBox(height: 12),

          _buildSensorProgressCard(
            title: 'Getaran · MPU6050',
            valueStr: '${getaran.toStringAsFixed(2)} m/s²',
            limitStr: 'Batas Normal < 1.50 m/s²',
            status: statusGetaran,
            pct: (getaran / 2.50).clamp(0.0, 1.0),
            icon: Icons.vibration,
          ),
          const SizedBox(height: 12),

          _buildSensorProgressCard(
            title: 'Suara · MAX4466',
            valueStr: '${suara.toStringAsFixed(2)} dB',
            limitStr: 'Batas Normal < 2.0 (Bahaya ≥ 2.50)',
            status: statusSuara,
            pct: (suara / 2.50).clamp(0.0, 1.0),
            icon: Icons.volume_up,
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendControlCommand('ON'),
                  icon: const Icon(Icons.power_settings_new, color: Colors.white),
                  label: const Text('NYALAKAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendControlCommand('OFF'),
                  icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
                  label: const Text('MATIKAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLedIndicator(String label, bool isActive, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? color : Colors.grey.shade400,
              boxShadow: isActive ? [BoxShadow(color: color, blurRadius: 6)] : [],
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: isActive ? Colors.black87 : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSensorProgressCard({
    required String title,
    required String valueStr,
    required String limitStr,
    required String status,
    required double pct,
    required IconData icon,
  }) {
    Color cardColor = _getColorByStatus(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.4), width: 1.2),
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
          CircleAvatar(
            backgroundColor: cardColor.withValues(alpha: 0.15),
            child: Icon(icon, color: cardColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text(valueStr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cardColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: cardColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text(limitStr, style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }
}