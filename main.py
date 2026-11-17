import json
import re
import paho.mqtt.client as mqtt
from supabase import create_client, Client

# Konfigurasi Supabase
SUPABASE_URL = "https://irqvoqevvuowcdhjlpmn.supabase.co"
SUPABASE_KEY = "sb_publishable_5gYJvgm77bWHr8vFDegjZw_3nWMtx_p"
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Konfigurasi MQTT
MQTT_BROKER = "broker.emqx.io"
MQTT_PORT = 1883
TELEMETRY_TOPIC = "kelkel4/telemetry"

# Ambang Batas Default (Bisa disesuaikan)
LIMIT_SUHU = 50.0      # °C
LIMIT_GETARAN = 1.0    # g
LIMIT_SUARA = 85.0     # dB

def hitung_status(suhu, getaran, suara):
    # Evaluasi status tingkat bahaya
    is_bahaya = (suhu > LIMIT_SUHU) or (getaran > LIMIT_GETARAN) or (suara > LIMIT_SUARA)
    is_waspada = (
        (suhu >= LIMIT_SUHU * 0.8) or 
        (getaran >= LIMIT_GETARAN * 0.8) or 
        (suara >= LIMIT_SUARA * 0.8)
    )
    
    if is_bahaya:
        return "Bahaya"
    elif is_waspada:
        return "Waspada"
    return "Normal"

def on_connect(client, userdata, flags, rc):
    print(f"Terhubung ke MQTT Broker dengan kode: {rc}")
    client.subscribe(TELEMETRY_TOPIC)

def on_message(client, userdata, msg):
    try:
        payload_str = msg.payload.decode('utf-8')
        print(f"Menerima pesan telemetri: {payload_str}")
        
        # Ekstrak data JSON atau String (Format: '20°C • 0.1 g • 69 dB')
        suhu, getaran, suara = 0.0, 0.0, 0.0
        
        if payload_str.startswith('{'):
            data_json = json.loads(payload_str)
            raw_msg = data_json.get('msg', '')
        else:
            raw_msg = payload_str

        # Pembersihan string & ekstrak angka
        clean_msg = raw_msg.replace('°C', '').replace('g', '').replace('dB', '')
        parts = [p.strip() for p in clean_msg.split('•')]

        if len(parts) >= 3:
            suhu = float(parts[0])
            getaran = float(parts[1])
            suara = float(parts[2])
        
        # Hitung Status Keseluruhan
        status = hitung_status(suhu, getaran, suara)
        
        # Simpan ke tabel Supabase 'riwayat_pengukuran'
        record = {
            "suhu": suhu,
            "getaran": getaran,
            "suara": suara,
            "status": status
        }
        
        res = supabase.table("riwayat_pengukuran").insert(record).execute()
        print(f" Data berhasil disimpan ke tabel 'riwayat_pengukuran': {record}")

    except Exception as e:
        print(f" Gagal memproses data telemetri: {e}")

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

print(f"Menghubungkan ke broker MQTT: {MQTT_BROKER}...")
client.connect(MQTT_BROKER, MQTT_PORT, 60)
client.loop_forever()