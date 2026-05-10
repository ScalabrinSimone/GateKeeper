#!/usr/bin/env bash
# Script di test che esegue richieste HTTP contro il server locale.
set -e

BASE=http://127.0.0.1:8000

echo "1) Create user"
curl -s -X POST "$BASE/users" -H "Content-Type: application/json" -d '{
  "username":"mario",
  "password":"secret",
  "email":"mario@example.com",
  "role":"adult",
  "current_location":"unknown"
}' | jq .

echo "2) Add device"
curl -s -X POST "$BASE/devices" -H "Content-Type: application/json" -d '{
  "name":"Sensor1",
  "rfid_tag":"E2000017221101441890ABCD",
  "category":"sensore",
  "is_essential":false,
  "current_status":"inside"
}' | jq .

echo "3) Associate user to device"
curl -s -X POST "$BASE/user-devices" -H "Content-Type: application/json" -d '{
  "user_id":1,
  "device_id":1
}' | jq .

echo "4) Add log"
curl -s -X POST "$BASE/logs" -H "Content-Type: application/json" -d '{
  "user_id":1,
  "device_id":1,
  "action":"ENTRATO"
}' | jq .

echo "5) Add event"
curl -s -X POST "$BASE/events" -H "Content-Type: application/json" -d '{
  "user_id":1,
  "event_type":"system",
  "direction":null,
  "detected_objects":[{"source":"test","value":"demo"}],
  "detected_users":[]
}' | jq .

echo "6) List users"
curl -s "$BASE/users" | jq .

echo "7) List devices"
curl -s "$BASE/devices" | jq .

echo "8) List associations"
curl -s "$BASE/user-devices" | jq .

echo "9) List logs"
curl -s "$BASE/logs" | jq .

echo "10) List events"
curl -s "$BASE/events" | jq .
