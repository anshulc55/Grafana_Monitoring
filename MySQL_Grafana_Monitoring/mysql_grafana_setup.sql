/**********************************************
* DATABASE & TABLE SETUP FOR GRAFANA MONITORING
**********************************************/

-- Create a dedicated database for Grafana monitoring data
CREATE DATABASE IF NOT EXISTS grafana_monitoring;
USE grafana_monitoring;

-- Table to store time-series metric snapshots
CREATE TABLE IF NOT EXISTS status (
  VARIABLE_NAME   VARCHAR(64)  CHARACTER SET utf8 NOT NULL DEFAULT '',
  VARIABLE_VALUE  VARCHAR(1024) CHARACTER SET utf8 DEFAULT NULL,
  TIMEST          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Table to store latest snapshot (used for delta calculations)
CREATE TABLE IF NOT EXISTS current (
  VARIABLE_NAME   VARCHAR(64) CHARACTER SET utf8 NOT NULL DEFAULT '',
  VARIABLE_VALUE  VARCHAR(1024) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB;

-- Add indexes for efficient lookups
ALTER TABLE status ADD UNIQUE KEY idx01 (VARIABLE_NAME, TIMEST);
ALTER TABLE current ADD UNIQUE KEY idx02 (VARIABLE_NAME);


/**********************************************
* PROCEDURE: collect_stats()
* Collects MySQL system metrics and stores them for Grafana
**********************************************/

DROP PROCEDURE IF EXISTS collect_stats;
DELIMITER //

CREATE PROCEDURE collect_stats()
BEGIN
  DECLARE a DATETIME;
  DECLARE v VARCHAR(10);
  SET sql_log_bin = 0;  -- Disable binary logging to avoid replication clutter

  SET a = NOW();        -- Capture current timestamp
  SELECT SUBSTR(VERSION(), 1, 3) INTO v;

  -- Collect numeric system variables from performance schema
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT UPPER(variable_name), variable_value, a
    FROM performance_schema.global_status
    WHERE variable_value REGEXP '^-*[[:digit:]]+(\.[[:digit:]]+)?$'
      AND variable_name NOT LIKE 'Performance_schema_%'
      AND variable_name NOT LIKE 'SSL_%';

  -- Track replication worker thread execution time
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT 'REPLICATION_MAX_WORKER_TIME', COALESCE(MAX(PROCESSLIST_TIME), 0.1), a
    FROM performance_schema.threads
    WHERE (NAME = 'thread/sql/slave_worker' AND (PROCESSLIST_STATE IS NULL OR PROCESSLIST_STATE != 'Waiting for an event from Coordinator'))
       OR NAME = 'thread/sql/slave_sql';

  -- Count active processes by user
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT CONCAT('PROCESSES.', user), COUNT(*), a
    FROM information_schema.processlist
    GROUP BY user;

  -- Count active processes by host
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT CONCAT('PROCESSES_HOSTS.', SUBSTRING_INDEX(host, ':', 1)), COUNT(*), a
    FROM information_schema.processlist
    GROUP BY CONCAT('PROCESSES_HOSTS.', SUBSTRING_INDEX(host, ':', 1));

  -- Count active processes by command type
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT CONCAT('PROCESSES_COMMAND.', command), COUNT(*), a
    FROM information_schema.processlist
    GROUP BY CONCAT('PROCESSES_COMMAND.', command);

  -- Count active processes by state
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT SUBSTR(CONCAT('PROCESSES_STATE.', state), 1, 64), COUNT(*), a
    FROM information_schema.processlist
    GROUP BY SUBSTR(CONCAT('PROCESSES_STATE.', state), 1, 64);

  -- Capture total wait time of all SQL statements
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT 'SUM_TIMER_WAIT', SUM(sum_timer_wait * 1.0), a
    FROM performance_schema.events_statements_summary_global_by_event_name;

  /***** CALCULATE DELTA VALUES BY COMPARING CURRENT SNAPSHOT *****/

  -- Delta for global status variables
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT CONCAT(UPPER(s.variable_name), '-d'), GREATEST(s.variable_value - c.variable_value, 0), a
    FROM performance_schema.global_status s
    JOIN grafana_monitoring.current c ON s.variable_name = c.variable_name;

  -- Delta for SQL statement counters
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT CONCAT('COM_', UPPER(SUBSTR(s.EVENT_NAME, 15, 58)), '-d'), GREATEST(s.COUNT_STAR - c.variable_value, 0), a
    FROM performance_schema.events_statements_summary_global_by_event_name s
    JOIN grafana_monitoring.current c ON s.EVENT_NAME = c.variable_name
    WHERE s.EVENT_NAME LIKE 'statement/sql/%';

  -- Delta for total statement wait time
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT 'SUM_TIMER_WAIT-d', SUM(sum_timer_wait * 1.0) - c.variable_value, a
    FROM performance_schema.events_statements_summary_global_by_event_name, grafana_monitoring.current c
    WHERE c.variable_name = 'SUM_TIMER_WAIT';

  -- Replication service statuses (as 0/1 flags)
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT 'REPLICATION_CONNECTION_STATUS', IF(SERVICE_STATE = 'ON', 1, 0), a
    FROM performance_schema.replication_connection_status;

  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT 'REPLICATION_APPLIER_STATUS', IF(SERVICE_STATE = 'ON', 1, 0), a
    FROM performance_schema.replication_applier_status;

  /***** UPDATE CURRENT SNAPSHOT FOR NEXT DELTA CALCULATION *****/

  DELETE FROM grafana_monitoring.current;

  -- Store current global status variables
  INSERT INTO grafana_monitoring.current(variable_name, variable_value)
    SELECT UPPER(variable_name), variable_value + 0
    FROM performance_schema.global_status
    WHERE variable_value REGEXP '^-*[[:digit:]]+(\.[[:digit:]]+)?$'
      AND variable_name NOT LIKE 'Performance_schema_%'
      AND variable_name NOT LIKE 'SSL_%';

  -- Store current SQL statement counters
  INSERT INTO grafana_monitoring.current(variable_name, variable_value)
    SELECT SUBSTR(EVENT_NAME, 1, 40), COUNT_STAR
    FROM performance_schema.events_statements_summary_global_by_event_name
    WHERE EVENT_NAME LIKE 'statement/sql/%';

  -- Store current total wait time
  INSERT INTO grafana_monitoring.current(variable_name, variable_value)
    SELECT 'SUM_TIMER_WAIT', SUM(sum_timer_wait * 1.0)
    FROM performance_schema.events_statements_summary_global_by_event_name;

  -- Store current process command counts
  INSERT INTO grafana_monitoring.current(variable_name, variable_value)
    SELECT CONCAT('PROCESSES_COMMAND.', command), COUNT(*)
    FROM information_schema.processlist
    GROUP BY CONCAT('PROCESSES_COMMAND.', command);

  -- Store key configuration variables
  INSERT INTO grafana_monitoring.current(variable_name, variable_value)
    SELECT UPPER(variable_name), variable_value
    FROM performance_schema.global_variables
    WHERE variable_name IN ('max_connections', 'innodb_buffer_pool_size', 'query_cache_size',
                            'innodb_log_buffer_size', 'key_buffer_size', 'table_open_cache');

  SET sql_log_bin = 1;
END //

DELIMITER ;


/**********************************************
* PROCEDURE: collect_daily_stats()
* Tracks DB and table size daily & purges old metrics
**********************************************/

DROP PROCEDURE IF EXISTS collect_daily_stats;
DELIMITER //

CREATE PROCEDURE collect_daily_stats()
BEGIN
  DECLARE a DATETIME;
  SET sql_log_bin = 0;
  SET a = NOW();

  -- Collect table sizes by schema
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT CONCAT('SIZEDB.', table_schema), SUM(data_length + index_length), a
    FROM information_schema.tables
    GROUP BY table_schema;

  -- Collect total DB size
  INSERT INTO grafana_monitoring.status(variable_name, variable_value, timest)
    SELECT 'SIZEDB.TOTAL', SUM(data_length + index_length), a
    FROM information_schema.tables;

  -- Clean up old metrics (retain 62 days; DB size kept for 1 year)
  DELETE FROM grafana_monitoring.status
    WHERE timest < DATE_SUB(NOW(), INTERVAL 62 DAY) AND variable_name <> 'SIZEDB.TOTAL';

  DELETE FROM grafana_monitoring.status
    WHERE timest < DATE_SUB(NOW(), INTERVAL 365 DAY);

  SET sql_log_bin = 1;
END //

DELIMITER ;



/**********************************************
* EVENT SCHEDULER SETUP
**********************************************/

-- Make sure the event scheduler is enabled in your my.cnf or runtime
SET GLOBAL event_scheduler = 1;

-- Schedule metrics collection every 5 minutes
SET sql_log_bin = 0;
DROP EVENT IF EXISTS collect_stats;
CREATE EVENT collect_stats
  ON SCHEDULE EVERY 5 MINUTE
  DO CALL collect_stats();

-- Schedule DB size stats collection daily
DROP EVENT IF EXISTS collect_daily_stats;
CREATE EVENT collect_daily_stats
  ON SCHEDULE EVERY 1 DAY
  DO CALL collect_daily_stats();
SET sql_log_bin = 1;


/**********************************************
* SECURITY SETUP FOR GRAFANA MONITORING USER
**********************************************/

-- Create dedicated monitoring user
CREATE USER 'grafana_monitoring'@'YOUR_USER'
  IDENTIFIED BY 'Your_Password';

-- Grant minimal required privileges
GRANT SELECT, INSERT, DELETE ON grafana_monitoring.* TO 'grafana_monitoring'@'YOUR_USER';
GRANT SELECT ON performance_schema.* TO 'grafana_monitoring'@'YOUR_USER';
GRANT PROCESS ON *.* TO 'grafana_monitoring'@'YOUR_USER';

-- Apply changes
FLUSH PRIVILEGES;
