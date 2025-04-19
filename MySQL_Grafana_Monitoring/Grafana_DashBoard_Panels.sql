/**********************************************
* This file Contains the SQL Queries 
* required for Diffirent Diffirent Panels
**********************************************/


/**********************************************
* Panel : Queries Per Second (QPS)
* Purpose : Monitor the rate of queries executed per second
* Panel Type : Time Series
**********************************************/
SELECT timest AS time, variable_value AS Query_Count
FROM grafana_monitoring.status
WHERE variable_name = 'QUERIES-d'
ORDER BY timest DESC




/**********************************************
* Panel : Top Commands Executed
* Purpose : Identify the most frequently executed SQL commands
* Panel Type : Bar Chart
**********************************************/
SELECT SUBSTRING_INDEX(variable_name, '.', -1) AS command,
         variable_value AS count
  FROM grafana_monitoring.status
  WHERE variable_name LIKE 'PROCESSES_COMMAND.%'
  ORDER BY count DESC
  LIMIT 10



/**********************************************
* Panel : Slow Queries Count
* Purpose : Monitor the number of slow queries to identify performance issues.
* Panel Type : Bar Chart
**********************************************/
SELECT timest AS time, variable_value AS Slow_Query_Count
  FROM grafana_monitoring.status
  WHERE variable_name = 'SLOW_QUERIES-d'
  ORDER BY timest DESC



/**********************************************
* Panel : Connections/Sec
* Purpose : Monitor Connections with  DB Per Sec
* Panel Type : Stat
**********************************************/
SELECT
  UNIX_TIMESTAMP(timest) as time_sec,
  variable_value/600 as value
FROM grafana_monitoring.status
WHERE $__timeFilter(timest)
  AND variable_name='CONNECTIONS-d'
  AND variable_value>=0
ORDER BY timest ASC




/**********************************************
* Panel : Space usage
* Purpose : Space Consumed by DB Per Day Stat
* Panel Type : Time Series
**********************************************/
SELECT
  $__timeGroup(timest,'1h') as time,
  variable_name as metric,
  avg(variable_value+0) as value
FROM grafana_monitoring.status
WHERE $__timeFilter(timest)
  and variable_name in ('SIZEDB.TOTAL')
GROUP BY 1,2
ORDER BY 1 ASC




/**********************************************
* Panel : InnoDB Buffer Pool Read Miss Ratio
* Purpose : Monitor the percentage of disk reads (misses) that 
* occurred because the data was not found in the InnoDB buffer pool.
* Panel Type : Gauge
**********************************************/
SELECT $__timeGroup(s1.timest,'30m') as time_sec,
  avg(1-s1.variable_value/s2.variable_value)*100 as value
FROM grafana_monitoring.status s1,  grafana_monitoring.status s2
WHERE $__timeFilter(s1.timest)
  AND s1.timest=s2.timest
  AND s1.variable_name='INNODB_BUFFER_POOL_READS-d'
  AND s2.variable_name='INNODB_BUFFER_POOL_READ_REQUESTS-d'
  AND s2.variable_value>0
GROUP BY 1
ORDER BY 1 ASC




/**********************************************
* Panel : User Activity Monitor
* Purpose : User Activity Monitoring
* Panel Type : Pie Chart    
**********************************************/
SELECT SUBSTRING_INDEX(variable_name, '.', -1) AS user,
       variable_value AS sessions
FROM grafana_monitoring.status
WHERE variable_name LIKE 'PROCESSES.%'
  AND timest > NOW() - INTERVAL 5 MINUTE
ORDER BY sessions DESC



/**********************************************
* Panel : MySQL network Incoming/Outgoing
* Purpose : Give you a time-series line chart, showing average network bytes per second
* Panel Type : Time Series
**********************************************/
SELECT $__timeGroup(timest, '10m') AS time,
       variable_name as metric,
       avg(variable_value+0)/600 as value
  FROM grafana_monitoring.status
 WHERE $__timeFilter(timest)
   and variable_name in ('Bytes_received-d', 'Bytes_sent-d')
 GROUP BY 1,2
 ORDER BY 1 ASC



/**********************************************
* Panel : Read I/O Thread Status
* Purpose : Visualize whether the Read I/O thread is running (1) or stopped (0). 
* Useful for replication health checks.
* Panel Type : stat
**********************************************/
SELECT 
  TIMEST AS time,
  VARIABLE_VALUE AS value,
  VARIABLE_NAME AS metric
FROM grafana_monitoring.status
WHERE VARIABLE_NAME = 'REPLICATION_CONNECTION_STATUS'
  AND TIMEST > NOW() - INTERVAL 1 HOUR
ORDER BY TIMEST;




/**********************************************
* Panel :  Number of MySQL Replication Slaves
* Purpose : Help to Identify the Replicatio Status Across the Cluster
* Panel Type : Time Series
**********************************************/
SELECT
  TIMEST as time,
  VARIABLE_VALUE as value,
  'Slave Count' as metric
FROM
  grafana_monitoring.status
WHERE
  VARIABLE_NAME = 'REPLICATION_MAX_WORKER_TIME'
ORDER BY TIMEST DESC
LIMIT 10;



/**********************************************
* Panel : Slave - sec. behind Master
* Purpose : Slave replication Lagging
* Panel Type : Stat
**********************************************/
SELECT
  UNIX_TIMESTAMP(timest) as time_sec,
  variable_value+0 as value
FROM grafana_monitoring.status
WHERE $__timeFilter(timest)
  AND (variable_name ='replication_worker_time' OR variable_name ='replication_max_worker_time')
ORDER BY timest ASC




/**********************************************
* Panel : Track Space Usage
* Purpose : Track space usage of each Database over time
* Panel Type : Bar Chart
**********************************************/
SELECT timest, 
       REPLACE(variable_name, 'SIZEDB.', '') AS DB_NAME,
       variable_value / (1024 * 1024 * 1024) AS size_GB
FROM grafana_monitoring.status
WHERE variable_name LIKE 'SIZEDB.%'




/**********************************************
* Panel : SQL Commands /sec
* Purpose : Total Select, Insert, Update, Delete Query Stats
* Panel Type : Time Series
**********************************************/
SELECT $__timeGroup(timest, '10m') AS time,
       substr(variable_name,5,length(variable_name)-6) as metric,
       avg(variable_value/600) as value
  FROM grafana_monitoring.status
 WHERE $__timeFilter(timest)
   and variable_name in ('COM_SELECT-d', 'COM_INSERT-d', 'COM_UPDATE-d', 'COM_DELETE-d')
   and variable_value >=0
 GROUP BY 1,2
 ORDER BY 1 ASC




/**********************************************
* Panel : MySQL threads (CONNECTED and RUNNING)
* Purpose : Visualize the average number of MySQL threads (CONNECTED and RUNNING)
* Panel Type : Time Series
**********************************************/
SELECT 
  $__timeGroup(timest, '1m') AS time,   -- Groups data in 1-minute buckets for time-series graph
  variable_name as metric,             -- Keeps 'THREADS_CONNECTED' and 'THREADS_RUNNING' as series labels
  avg(variable_value+0) as value       -- Averages numeric values (forcing string to number with +0)
FROM grafana_monitoring.status
WHERE 
  $__timeFilter(timest)                -- Filters based on selected dashboard time range
  AND variable_name in ('THREADS_CONNECTED', 'THREADS_RUNNING')  -- Only select these two MySQL metrics
GROUP BY 1,2                           -- Groups by time bucket and metric name
ORDER BY 1 ASC                         -- Orders chronologically




/**********************************************
* Panel : Heatmap (Queries /sec)
* Purpose : Heatmap (Queries /sec)
* Panel Type : Heatmap
**********************************************/
SELECT
  $__timeGroup(timest, '1h') as time,
  concat(' ',max(date_format(timest,'%H'))) as metric,
  sum(variable_value)/3600 as value
FROM grafana_monitoring.status
WHERE variable_name='QUERIES-d'
  and variable_value>0
  and $__timeFilter(timest)
GROUP BY $__timeGroup(timest, '1h'),$__timeGroup(timest, '1h')
ORDER BY $__timeGroup(timest, '1h'),$__timeGroup(timest, '1h')




/**********************************************
* Panel : Top Commands Executed (1 Hr)
* Purpose : Final Last Hour Top Executed Commands
* Panel Type : Bar Chart
**********************************************/
SELECT 
  SUBSTRING_INDEX(variable_name, '.', -1) AS command,
  variable_value AS count
FROM grafana_monitoring.status
WHERE variable_name LIKE 'PROCESSES_COMMAND.%'
  AND variable_value > 0
  AND TIMEST > NOW() - INTERVAL 1 HOUR
ORDER BY count DESC;