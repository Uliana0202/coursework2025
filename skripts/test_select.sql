use course_db;

CREATE TABLE test_select_query (
    tables Array(String),
    query String,
    event_time DateTime,
    query_duration_ms UInt64,
    read_rows UInt64,
    read_bytes UInt64,
    memory_usage UInt64,
    projections Array(String),
    views Array(String)
) ENGINE = MergeTree()
ORDER BY event_time;


-- Аналитика по всем запросам
SELECT 
    tables,
    sum(query_duration_ms) AS total_duration_ms,
    sum(read_rows) AS total_read_rows,
    sum(read_bytes) AS total_read_bytes,
    sum(memory_usage) AS total_memory_usage,
    count() AS query_count
FROM test_select_query
GROUP BY tables
ORDER BY total_duration_ms;


-- Аналитика по определенному классу запросов
SELECT 
    tables,
    sum(query_duration_ms) AS total_duration_ms,
    sum(read_rows) AS total_read_rows,
    sum(read_bytes) AS total_read_bytes,
    sum(memory_usage) AS total_memory_usage,
    count() AS query_count
FROM test_select_query
WHERE 
    query NOT LIKE '%login%' AND
    --query NOT LIKE '%event%'
    query NOT LIKE '%subsystem%'
GROUP BY tables
ORDER BY total_duration_ms ;

