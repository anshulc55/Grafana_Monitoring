/**********************************************
* Create Grafana user in Database for Grafana Server
**********************************************/

CREATE USER 'YOUR_USER'@'SOURCE_IP' IDENTIFIED BY 'YOUR_PASSWORD';
GRANT SELECT ON DB_YOU_MONITOR.* TO 'YOUR_USER'@'SOURCE_IP';
FLUSH PRIVILEGES;
quit


/**********************************************
* Check DB From Explorer
**********************************************/

SELECT
  variable_value+0 as value,
  timest as time_sec
FROM grafana_monitoring.status
WHERE variable_name='THREADS_CONNECTED'
ORDER BY timest ASC;