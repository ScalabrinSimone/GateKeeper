#!/usr/bin/env bash
set -e
BASE=http://127.0.0.1:8000

echo "1) Create user"
curl -s -X POST "$BASE/users" -H "Content-Type: application/json" -d '{"username":"mario","password":"secret"}' | jq .

echo "2) Add device"
curl -s -X POST "$BASE/devices" -H "Content-Type: application/json" -d '{"name":"Sensor1"}' | jq .

echo "3) Associate user to device"
curl -s -X POST "$BASE/associate" -H "Content-Type: application/json" -d '{"user_id":1,"device_id":1}' | jq .

echo "4) Add log"
curl -s -X POST "$BASE/logs" -H "Content-Type: application/json" -d '{"user_id":1,"device_id":1,"action":"ENTRATO"}' | jq .

echo "5) List logs"
curl -s "$BASE/logs" | jq .
