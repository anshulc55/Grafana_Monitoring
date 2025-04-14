#!/bin/bash
set +H  # Disable history expansion to allow '!' in passwords

# Configuration
MYSQL_USER="loaduser"
MYSQL_PASS="StrongPassword"
MYSQL_DB="grafana_monitor"

# Loop forever to simulate continuous DB load
while true; do
  echo "🚀 Generating MySQL load at $(date)..."

  # Simulate active threads and sleeping processes
  for i in {1..10}; do
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -D"$MYSQL_DB" -e "SELECT SLEEP(0.5);" &
  done

  # Simulate CPU-intensive queries
  for i in {1..5}; do
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -D"$MYSQL_DB" -e "SELECT BENCHMARK(500000, SHA2('LOADTEST', 512));" &
  done

  # Insert lots of rows with dummy metrics (affects INSERT counters and performance)
  for i in {1..20}; do
    RAND_VAL=$(shuf -i 1000-9999 -n 1)
    mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -D"$MYSQL_DB" -e "INSERT INTO status (VARIABLE_NAME, VARIABLE_VALUE) VALUES (UUID(), '$RAND_VAL');" &
  done

  # Fake multiple hosts/users (will likely fail unless users exist, but good for testing failure/permissions)
  for user in user1 user2 user3 user4; do
    mysql -u"$user" -p"$MYSQL_PASS" -D"$MYSQL_DB" --host=127.0.0.1 -e "SELECT SLEEP(0.1);" &
  done

  # Random metadata stress test
  mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -D"$MYSQL_DB" -e "
    SELECT table_name, engine, table_rows 
    FROM information_schema.tables 
    WHERE table_schema='mysql' 
    ORDER BY RAND() LIMIT 5;" &

  # Simulate high I/O scan
  mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" -D"$MYSQL_DB" -e "
    SELECT COUNT(*) FROM information_schema.columns;" &

  sleep 5
done
