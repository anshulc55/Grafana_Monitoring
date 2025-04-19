#!/bin/bash

# Configuration
USER="loaduser"
PASS="StrongPassword"
DB="grafana_monitoring"

# Helper: Execute SQL
exec_sql() {
  mysql -u$USER -p$PASS -D$DB -se "$1"
}

echo "[+] Starting heavy DB load simulation..."

while true; do

  echo "[*] Heavy SELECTs + Slow Queries"
  # 20 Quick SELECTs
  for i in {1..20}; do
    exec_sql "SELECT * FROM status ORDER BY TIMEST DESC LIMIT 10;"
  done

  # 5 Slow SELECTs
  for i in {1..5}; do
    exec_sql "SELECT SLEEP(2);"
  done

  # CPU-Intensive SQL
  for i in {1..10}; do
    exec_sql "SELECT BENCHMARK(1000000, SHA2('stress_test', 256));"
  done

  echo "[*] INSERT Flood"
  # Insert 50 rows with random values
  for i in {1..50}; do
    VALUE=$RANDOM
    exec_sql "INSERT INTO status (VARIABLE_NAME, VARIABLE_VALUE) VALUES (CONCAT('LOAD_', UUID()), '$VALUE');"
  done

  echo "[*] UPDATE Storm"
  # Random updates to simulate cache invalidations and buffer pool pressure
  for i in {1..20}; do
    VALUE=$RANDOM
    exec_sql "UPDATE status SET VARIABLE_VALUE = '$VALUE' WHERE VARIABLE_NAME IN (SELECT VARIABLE_NAME FROM status ORDER BY RAND() LIMIT 1);"
  done

  echo "[*] Table Cache & Temp Table Simulation"
  # Join queries to create internal temp tables
  exec_sql "SELECT s1.VARIABLE_NAME, s2.VARIABLE_VALUE 
            FROM status s1 JOIN status s2 ON s1.VARIABLE_NAME = s2.VARIABLE_NAME 
            ORDER BY s1.TIMEST DESC LIMIT 100;"

  # ORDER BY with LIMIT (uses buffer/cache)
  exec_sql "SELECT * FROM status ORDER BY VARIABLE_VALUE DESC LIMIT 50;"

  echo "[*] Increasing process list and table open cache pressure"
  # Open many connections in background to mimic concurrent usage
  for i in {1..5}; do
    mysql -u$USER -p$PASS -D$DB -e "SELECT SLEEP(5);" &
  done

  # Optional: Short sleep before next loop
  sleep 2

done
