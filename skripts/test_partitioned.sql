use course_db;

CREATE TABLE test_partitioned
(
    tables Array(String),
    query String,
    event_time DateTime,
    query_duration_ms UInt64,
    read_rows UInt64,
    read_bytes UInt64,
    memory_usage UInt64,
    projections Array(String),
    views Array(String)
)
ENGINE = MergeTree
ORDER BY event_time
SETTINGS index_granularity = 8192;

TRUNCATE TABLE system.query_log;

-- Для таблицы logs_full_scan
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM  logs_full_scan
WHERE timestamp BETWEEN '2013-01-16 20:19:58' AND '2014-04-16 20:19:58'
ORDER BY timestamp DESC;

-- Для таблицы logs_ordered
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM  logs_ordered
WHERE timestamp BETWEEN '2013-01-16 20:19:58' AND '2014-04-16 20:19:58'
ORDER BY timestamp DESC;

-- Для таблицы logs_with_indexes
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM  logs_with_indexes
WHERE timestamp BETWEEN '2013-01-16 20:19:58' AND '2014-04-16 20:19:58'
ORDER BY timestamp DESC;

-- Для таблицы logs_with_projections
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM  logs_with_projections
WHERE timestamp BETWEEN '2013-01-16 20:19:58' AND '2014-04-16 20:19:58'
ORDER BY timestamp DESC;

-- Для таблицы logs_partitioned
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM logs_partitioned
WHERE timestamp BETWEEN '2013-01-16 20:19:58' AND '2014-04-16 20:19:58'
ORDER BY timestamp DESC;


INSERT INTO test_partitioned
SELECT 
	tables,
    query,
    event_time,
    query_duration_ms,
    read_rows,
    read_bytes,
    memory_usage,
    projections,
    views 
FROM system.query_log
WHERE query_duration_ms > 0
	AND query LIKE 'SELECT %'