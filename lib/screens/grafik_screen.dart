import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_monitoring/services/mqtt_service.dart';
import 'package:smart_monitoring/models/sensor_model.dart';

class GrafikScreen extends StatefulWidget {
  final MqttService mqttService;
  final String userRole;

  const GrafikScreen({
    super.key,
    required this.mqttService,
    required this.userRole,
  });

  @override
  State<GrafikScreen> createState() => _GrafikScreenState();
}

class _GrafikScreenState extends State<GrafikScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  String selectedSensor = 'Suhu';
  String selectedTimeRange = '24 Jam'; // '1 Jam', '6 Jam', '24 Jam'

  final List<SensorDataPoint> _dataHistory = [];
  bool _isLoadingGrafik = true;
  late DateTime _waktuMulaiSiklus;
  Timer? _timerResetHarian;

  @override
  void initState() {
    super.initState();
    _waktuMulaiSiklus = DateTime.now();
    _mulaiTimerReset24Jam();
    
    _inisialisasiNilaiBatasAsli();

    _fetchInitialGrafikData();
    widget.mqttService.sensorDataNotifier.addListener(_onSensorDataChanged);
    
    widget.mqttService.batasSuhuNotifier.addListener(_onBatasChanged);
    widget.mqttService.batasGetaranNotifier.addListener(_onBatasChanged);
    widget.mqttService.batasSuaraNotifier.addListener(_onBatasChanged);
  }

  void _inisialisasiNilaiBatasAsli() {
    if (widget.mqttService.batasSuhuNotifier.value < 40.0 || widget.mqttService.batasSuhuNotifier.value == 50.0) {
      widget.mqttService.batasSuhuNotifier.value = 60.0;
    }
    if (widget.mqttService.batasGetaranNotifier.value < 0.1 || widget.mqttService.batasGetaranNotifier.value == 1.80) {
      widget.mqttService.batasGetaranNotifier.value = 2.50;
    }
    if (widget.mqttService.batasSuaraNotifier.value < 0.5 || widget.mqttService.batasSuaraNotifier.value > 100.0) {
      widget.mqttService.batasSuaraNotifier.value = 2.50;
    }
  }

  @override
  void dispose() {
    widget.mqttService.sensorDataNotifier.removeListener(_onSensorDataChanged);
    widget.mqttService.batasSuhuNotifier.removeListener(_onBatasChanged);
    widget.mqttService.batasGetaranNotifier.removeListener(_onBatasChanged);
    widget.mqttService.batasSuaraNotifier.removeListener(_onBatasChanged);
    _timerResetHarian?.cancel();
    super.dispose();
  }

  void _onBatasChanged() {
    if (mounted) setState(() {});
  }

  // Mengambil dan memfilter data berdasarkan pilihan rentang waktu
  Future<void> _fetchInitialGrafikData() async {
    setState(() {
      _isLoadingGrafik = true;
    });

    try {
      final response = await supabase
          .from('riwayat_pengukuran')
          .select()
          .order('created_at', ascending: true);

      List rawList = List.from(response);
      List<SensorDataPoint> loadedPoints = [];
      DateTime now = DateTime.now();

      // Tentukan batas jam berdasarkan pilihan rentang waktu
      int batasJam = 24;
      if (selectedTimeRange == '1 Jam') {
        batasJam = 1;
      } else if (selectedTimeRange == '6 Jam') {
        batasJam = 6;
      }

      for (var item in rawList) {
        String createdAtStr = item['created_at'] ?? '';
        DateTime? itemTime = DateTime.tryParse(createdAtStr);

        if (itemTime != null) {
          DateTime localTime = itemTime.toLocal();
          Duration selisihWaktu = now.difference(localTime);

          // Filter data sesuai rentang jam yang dipilih
          if (selisihWaktu.inHours < batasJam && !selisihWaktu.isNegative) {
            loadedPoints.add(SensorDataPoint(
              time: localTime,
              suhu: (item['suhu'] as num?)?.toDouble() ?? 0.0,
              getaran: (item['getaran'] as num?)?.toDouble() ?? 0.0,
              suara: (item['suara'] as num?)?.toDouble() ?? 0.0,
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _dataHistory.clear();
          _dataHistory.addAll(loadedPoints);
          _isLoadingGrafik = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGrafik = false;
        });
      }
    }
  }

  void _onSensorDataChanged() {
    SensorModel? data = widget.mqttService.sensorDataNotifier.value;
    
    if (data != null && mounted) {
      setState(() {
        _dataHistory.add(SensorDataPoint(
          time: DateTime.now(),
          suhu: data.suhu,
          getaran: data.getaran,
          suara: data.suara,
        ));

        // Bersihkan data lama yang melebihi rentang waktu aktif
        _filterDataByTimeRange();

        if (_dataHistory.length > 500) {
          _dataHistory.removeAt(0);
        }
      });
    }
  }

  // Menyaring data secara dinamis di memory agar sesuai rentang waktu aktif
  void _filterDataByTimeRange() {
    DateTime now = DateTime.now();
    int batasJam = 24;
    if (selectedTimeRange == '1 Jam') {
      batasJam = 1;
    } else if (selectedTimeRange == '6 Jam') {
      batasJam = 6;
    }

    _dataHistory.removeWhere((point) {
      Duration selisih = now.difference(point.time);
      return selisih.inHours >= batasJam || selisih.isNegative;
    });
  }

  void _mulaiTimerReset24Jam() {
    _timerResetHarian = Timer.periodic(const Duration(minutes: 5), (timer) {
      final durasiBerjalan = DateTime.now().difference(_waktuMulaiSiklus);
      
      if (durasiBerjalan.inHours >= 24) {
        if (_dataHistory.isNotEmpty) {
          final waktuDataTerakhir = _dataHistory.last.time;
          final jedaTanpaData = DateTime.now().difference(waktuDataTerakhir);

          if (jedaTanpaData.inHours >= 24) {
            if (mounted) {
              setState(() {
                _waktuMulaiSiklus = DateTime.now();
                _dataHistory.clear();
              });
            }
          }
        }
      }
    });
  }

  double get currentValue {
    if (_dataHistory.isEmpty) {
      SensorModel? data = widget.mqttService.sensorDataNotifier.value;
      if (data == null) return 0.0;
      if (selectedSensor == 'Suhu') return data.suhu;
      if (selectedSensor == 'Getaran') return data.getaran;
      return data.suara;
    }

    final latest = _dataHistory.last;
    if (selectedSensor == 'Suhu') return latest.suhu;
    if (selectedSensor == 'Getaran') return latest.getaran;
    return latest.suara;
  }

  double get currentBatas {
    if (selectedSensor == 'Suhu') {
      double val = widget.mqttService.batasSuhuNotifier.value;
      if (val < 40.0) return 60.0;
      return val;
    }
    if (selectedSensor == 'Getaran') {
      double val = widget.mqttService.batasGetaranNotifier.value;
      if (val < 0.1) return 2.50;
      return val;
    }
    double val = widget.mqttService.batasSuaraNotifier.value;
    if (val < 0.5) return 2.50;
    return val;
  }

  String get nilaiWaspadaStr {
    if (selectedSensor == 'Suhu') return '40.0 °C';
    if (selectedSensor == 'Getaran') return '1.50 m/s²';
    return '2.0 dB';
  }

  bool get isDiAtasBatas => currentValue > currentBatas;

  void _ubahBatas(double delta) {
    double nilaiBaru = currentBatas + delta;
    if (selectedSensor == 'Suhu') {
      nilaiBaru = nilaiBaru.clamp(20.0, 100.0);
      widget.mqttService.perbaruiAmbangBatas('Suhu', nilaiBaru);
    } else if (selectedSensor == 'Getaran') {
      nilaiBaru = nilaiBaru.clamp(0.1, 10.0);
      widget.mqttService.perbaruiAmbangBatas('Getaran', nilaiBaru);
    } else if (selectedSensor == 'Suara') {
      nilaiBaru = nilaiBaru.clamp(0.1, 10.0);
      widget.mqttService.perbaruiAmbangBatas('Suara', nilaiBaru);
    }
    setState(() {});
  }

  String _formatWaktu(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    bool isAdmin = widget.userRole.toLowerCase() == 'admin';

    String waktuMulaiStr = _dataHistory.isNotEmpty ? _formatWaktu(_dataHistory.first.time) : '00:00';
    String waktuAkhirStr = _dataHistory.isNotEmpty ? _formatWaktu(_dataHistory.last.time) : '24:00';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Grafik',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Pilihan Sensor
            Row(
              children: ['Suhu', 'Getaran', 'Suara'].map((sensor) {
                bool isSelected = selectedSensor == sensor;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(sensor),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2E7CF6),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        selectedSensor = sensor;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Pilihan Rentang Waktu (Memanggil ulang fetch data berdasarkan waktu yang dipilih)
            Row(
              children: ['1 Jam', '6 Jam', '24 Jam'].map((time) {
                bool isSelected = selectedTimeRange == time;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(time),
                    selected: isSelected,
                    selectedColor: const Color(0xFF1E56D9),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        selectedTimeRange = time;
                      });
                      // Ambil ulang data dari Supabase dengan filter waktu yang baru
                      _fetchInitialGrafikData();
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Card Kontainer Grafik Utama
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$selectedSensor Motor · ${selectedSensor == 'Getaran' ? 'MPU6050' : selectedSensor == 'Suara' ? 'MAX4466' : 'DS18B20'}',
                        style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (isDiAtasBatas)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade700),
                          ),
                          child: const Text(
                            'Di atas batas',
                            style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dataHistory.isEmpty 
                        ? 'Menunggu data real-time...' 
                        : '${currentValue.toStringAsFixed(2)} ${selectedSensor == 'Getaran' ? 'm/s²' : selectedSensor == 'Suhu' ? '°C' : 'dB'}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  
                  // Container Grafik
                  Container(
                    height: 200,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: _isLoadingGrafik
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7CF6)))
                        : CustomPaint(
                            size: const Size(double.infinity, 200),
                            painter: DynamicLineChartPainter(
                              history: List.from(_dataHistory),
                              sensorType: selectedSensor,
                              threshold: currentBatas,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(waktuMulaiStr, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(waktuAkhirStr, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Panel Atur Batas Bahaya
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Atur Batas Bahaya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                      Text(
                        isAdmin ? 'Waspada mulai $nilaiWaspadaStr' : 'Mode Read-Only',
                        style: TextStyle(color: isAdmin ? Colors.black54 : Colors.orange.shade800, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.remove, color: Colors.black87),
                        onPressed: isAdmin ? () => _ubahBatas(-0.1) : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          '${currentBatas.toStringAsFixed(2)} ${selectedSensor == 'Getaran' ? 'm/s²' : selectedSensor == 'Suhu' ? '°C' : 'dB'}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(Icons.add, color: Colors.black87),
                        onPressed: isAdmin ? () => _ubahBatas(0.1) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SensorDataPoint {
  final DateTime time;
  final double suhu;
  final double getaran;
  final double suara;

  SensorDataPoint({required this.time, required this.suhu, required this.getaran, required this.suara});
}

class DynamicLineChartPainter extends CustomPainter {
  final List<SensorDataPoint> history;
  final String sensorType;
  final double threshold;

  DynamicLineChartPainter({required this.history, required this.sensorType, required this.threshold});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF2E7CF6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintThreshold = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = const Color(0xFF1E56D9)
      ..style = PaintingStyle.fill;

    final paintDotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double paddingLeft = 65.0;
    double paddingRight = 20.0;
    double drawWidth = size.width - (paddingLeft + paddingRight);

    double minVal = 0.0;
    double maxVal = threshold * 1.25;
    
    if (sensorType == 'Suara' && maxVal < 3.0) {
      maxVal = 3.0;
    } else if (sensorType == 'Suhu' && maxVal < 75.0) {
      maxVal = 75.0;
    } else if (sensorType == 'Getaran' && maxVal < 3.0) {
      maxVal = 3.0;
    }
    if (maxVal == 0) maxVal = 100.0;

    double normalizedThresholdY = 1.0 - ((threshold - minVal) / (maxVal - minVal == 0 ? 1 : maxVal - minVal));
    double thresholdY = (normalizedThresholdY * (size.height - 40)) + 20;

    final textBatasSpan = TextSpan(
      text: 'Batas\n${threshold.toStringAsFixed(2)}',
      style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, height: 1.1),
    );
    final textBatasPainter = TextPainter(
      text: textBatasSpan,
      textDirection: TextDirection.ltr,
    );
    textBatasPainter.layout();
    textBatasPainter.paint(canvas, Offset(4, thresholdY - 14));

    double dashWidth = 6, dashSpace = 4, startX = paddingLeft;
    while (startX < size.width - paddingRight) {
      canvas.drawLine(Offset(startX, thresholdY), Offset(startX + dashWidth, thresholdY), paintThreshold);
      startX += dashWidth + dashSpace;
    }

    if (history.isEmpty) return;

    final path = Path();
    List<Offset> points = [];

    for (int i = 0; i < history.length; i++) {
      double val = sensorType == 'Suhu'
          ? history[i].suhu
          : sensorType == 'Getaran'
              ? history[i].getaran
              : history[i].suara;

      double x = paddingLeft + (i / (history.length > 1 ? history.length - 1 : 1)) * drawWidth;
      double normalizedY = 1.0 - ((val - minVal) / (maxVal - minVal == 0 ? 1 : maxVal - minVal));
      double y = (normalizedY * (size.height - 40)) + 20;

      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paintLine);

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, paintDot);
      canvas.drawCircle(points[i], 4, paintDotBorder);

      double val = sensorType == 'Suhu'
          ? history[i].suhu
          : sensorType == 'Getaran'
              ? history[i].getaran
              : history[i].suara;

      String satuan = sensorType == 'Getaran' 
          ? ' m/s²' 
          : (sensorType == 'Suhu' ? ' °C' : ' dB');
          
      String labelTeks = '${val.toStringAsFixed(2)}$satuan\n${history[i].time.hour.toString().padLeft(2, '0')}:${history[i].time.minute.toString().padLeft(2, '0')}';

      if (history.length <= 10) {
        final textSpan = TextSpan(
          text: labelTeks,
          style: const TextStyle(
            color: Colors.black87, 
            fontSize: 11, 
            fontWeight: FontWeight.bold, 
            height: 1.2,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        
        double textX = points[i].dx - (textPainter.width / 2);
        if (textX < paddingLeft) textX = paddingLeft;
        if (textX + textPainter.width > size.width - 20) {
          textX = size.width - textPainter.width - 20;
        }

        textPainter.paint(canvas, Offset(textX, points[i].dy - 38));
      }
    }
  }

  @override
  bool shouldRepaint(covariant DynamicLineChartPainter oldDelegate) {
    return true;
  }
}