class SensorModel {
  final double suhu;
  final double getaran;
  final double suara;
  final String status;

  SensorModel({
    required this.suhu,
    required this.getaran,
    required this.suara,
    required this.status,
  });

  // Memetakan kiriman JSON dari ESP32 atau MQTT menjadi objek data Flutter
  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      suhu: (json['suhu'] as num).toDouble(),
      getaran: (json['getaran'] as num).toDouble(),
      suara: (json['suara'] as num).toDouble(),
      status: json['status'] ?? 'Normal',
    );
  }
}
