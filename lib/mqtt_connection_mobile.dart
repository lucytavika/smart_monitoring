import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClient(String clientId) {
  final client = MqttServerClient(
    'broker.emqx.io',
    clientId,
  );

  client.port = 1883;
  client.secure = false;
  client.keepAlivePeriod = 60;

  return client;
}