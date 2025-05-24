use course_db;
DROP VIEW IF EXISTS failed_events_mv;

CREATE TABLE test_view
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

CREATE MATERIALIZED VIEW failed_events_mv
ENGINE = MergeTree()
ORDER BY (timestamp, login)
POPULATE 
AS
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM logs_ordered
WHERE event LIKE '%_failed';

SELECT * FROM failed_events_mv;

-- Для таблицы logs_full_scan
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM logs_full_scan
WHERE event LIKE '%_failed'
ORDER BY timestamp DESC;

-- Для таблицы logs_ordered
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM logs_ordered
WHERE event LIKE '%_failed'
ORDER BY timestamp DESC;

-- Для таблицы logs_with_indexes
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM logs_with_indexes
WHERE event LIKE '%_failed'
ORDER BY timestamp DESC;

-- Для таблицы logs_with_projections
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM logs_with_projections
WHERE event LIKE '%_failed'
ORDER BY timestamp DESC;

-- Для таблицы logs_partitioned
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM logs_partitioned
WHERE event LIKE '%_failed'
ORDER BY timestamp DESC;

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
WHERE query_duration_ms > 0;

INSERT INTO test_view
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
AND ( query LIKE 'SELECT %' OR query LIKE 'CREATE %' )