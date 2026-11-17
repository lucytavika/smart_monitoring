import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sensor_model.dart';
import '../mqtt_connection.dart';

class MqttService {
  late MqttClient client;
  final String clientId;
  final SupabaseClient supabase = Supabase.instance.client;

  final String telemetryTopic = 'kelkel4/telemetry';
  final String fanStateTopic = 'kelkel4/fan/status'; 
  final String fanTopic = 'kelkel4/fan';
  final String setpointTopic = 'kelkel4/setpoint';

  ValueNotifier<SensorModel?> sensorDataNotifier = ValueNotifier<SensorModel?>(null);
  ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);
  
  // Disesuaikan dengan batas default baru (Suhu 60.0, Getaran 2.50, Suara 2.50)
  ValueNotifier<double> batasSuhuNotifier = ValueNotifier<double>(60.0);
  ValueNotifier<double> batasGetaranNotifier = ValueNotifier<double>(2.50);
  ValueNotifier<double> batasSuaraNotifier = ValueNotifier<double>(2.50);

  String? _lastLoggedStatus;

  MqttService({required this.clientId});

  Future<void> connect() async {
    try {
      client = createMqttClient(clientId);
      client.keepAlivePeriod = 60;
      client.autoReconnect = true;
      client.resubscribeOnAutoReconnect = true;

      client.onConnected = () {
        isConnectedNotifier.value = true;
        client.subscribe(telemetryTopic, MqttQos.atMostOnce);
        client.subscribe(fanStateTopic, MqttQos.atMostOnce);
      };

      client.onDisconnected = () {
        isConnectedNotifier.value = false;
      };

      await client.connect();

      client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        for (final received in messages) {
          final message = received.payload as MqttPublishMessage;
          final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);

          if (received.topic == telemetryTopic) {
            try {
              Map<String, dynamic> jsonMap = jsonDecode(payload);

              double suhu = double.tryParse(jsonMap['suhu']?.toString() ?? '0') ?? 0.0;
              double getaran = double.tryParse(jsonMap['getaran']?.toString() ?? '0') ?? 0.0;
              double suara = double.tryParse(jsonMap['suara']?.toString() ?? '0') ?? 0.0;

              String status = "Normal";
              if (suhu > batasSuhuNotifier.value || 
                  getaran > batasGetaranNotifier.value || 
                  suara > batasSuaraNotifier.value) {
                status = "Bahaya";
              } else if (suhu >= (batasSuhuNotifier.value * 0.8) || 
                         getaran >= (batasGetaranNotifier.value * 0.8) || 
                         suara >= (batasSuaraNotifier.value * 0.8)) {
                status = "Waspada";
              }

              String currentStatusUpper = status.toUpperCase();
              String? lastLoggedUpper = _lastLoggedStatus?.toUpperCase();

              if (_lastLoggedStatus == null || currentStatusUpper != lastLoggedUpper) {
                _lastLoggedStatus = status;
                _simpanPerubahanKeSupabase(status, suhu, getaran, suara);
              }

              sensorDataNotifier.value = SensorModel(
                suhu: suhu, 
                getaran: getaran, 
                suara: suara, 
                status: status,
              );
            } catch (e) {
              debugPrint("Gagal parsing JSON telemetry: $e");
            }
          }
        }
      });
    } catch (e) {
      isConnectedNotifier.value = false;
      debugPrint("Gagal koneksi MQTT: $e");
    }
  }

  Future<void> _simpanPerubahanKeSupabase(String status, double suhu, double getaran, double suara) async {
    try {
      await supabase.from('riwayat_pengukuran').insert({
        'status': status,
        'suhu': suhu,
        'getaran': getaran,
        'suara': suara,
      });
      debugPrint("Riwayat status '$status' berhasil disimpan ke Supabase.");
    } catch (e) {
      debugPrint("Gagal menyimpan riwayat ke Supabase: $e");
    }
  }

  void perbaruiAmbangBatas(String tipe, double nilai) {
    if (tipe == "Suhu") batasSuhuNotifier.value = nilai;
    if (tipe == "Getaran") batasGetaranNotifier.value = nilai;
    if (tipe == "Suara") batasSuaraNotifier.value = nilai;

    Map<String, dynamic> setpointPayload = {"tipe": tipe, "batas": nilai};
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder()..addString(jsonEncode(setpointPayload));
      client.publishMessage(setpointTopic, MqttQos.atMostOnce, builder.payload!);
    }
  }

  void publish(String topic, String message) {
    if (client.connectionStatus?.state != MqttConnectionState.connected) return;
    final builder = MqttClientPayloadBuilder()..addString(message);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  void setFan(bool state) => publish(fanTopic, state ? 'ON' : 'OFF');

  void disconnect() {
    try {
      if (client.connectionStatus?.state == MqttConnectionState.connected) {
        client.disconnect();
      }
    } catch (_) {}
  }
}