import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient createMqttClient(String clientId) {
  final client = MqttBrowserClient(
    'ws://broker.emqx.io/mqtt',
    clientId,
  );

  client.port = 8083;
  client.keepAlivePeriod = 60;

  return client;
}