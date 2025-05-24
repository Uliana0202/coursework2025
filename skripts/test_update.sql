use course_db;


CREATE TABLE test_update
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

-- Для таблиц с индексами 
-- Для logs_with_indexes 
ALTER TABLE logs_with_indexes 
UPDATE 
    comment = 'two tee to two two'
WHERE subsystem = '2000-07-05 08:27:55';

ALTER TABLE logs_with_indexes 
UPDATE 
	description = 'hello world'
WHERE subsystem = 'bd';

-- Для logs_with_indexes_v2 (ReplacingMergeTree)
ALTER TABLE logs_with_indexes_v2 
UPDATE 
    comment = 'two tee to two two'
WHERE timestamp = '2000-07-05 08:27:55';

ALTER TABLE logs_with_indexes_v2 
UPDATE 
    description = 'hello world'
WHERE subsystem = 'bd';

-- Для logs_with_indexes_v3 и logs_with_indexes_metadata
ALTER TABLE logs_with_indexes_metadata 
UPDATE 
    comment = 'two tee to two two'
WHERE log_id IN (
    SELECT log_id 
    FROM logs_with_indexes_v3 
    WHERE timestamp = '2000-07-05 08:27:55'
);

ALTER TABLE logs_with_indexes_metadata 
UPDATE 
    description = 'hello world'
WHERE log_id IN (
    SELECT log_id 
    FROM logs_with_indexes_v3 
    WHERE subsystem = 'bd'
);

-- Оптимизация таблиц
OPTIMIZE TABLE logs_with_indexes FINAL;
OPTIMIZE TABLE logs_with_indexes_v2 FINAL;
OPTIMIZE TABLE logs_with_indexes_v3 FINAL;
OPTIMIZE TABLE logs_with_indexes_metadata FINAL;

-- Для таблиц с проекциями (logs_with_projections_v2 и logs_with_projections_v3)
-- Для logs_with_projections
ALTER TABLE logs_with_projections 
UPDATE 
    comment = 'two tee to two two'
WHERE timestamp = '2000-07-05 08:27:55';

ALTER TABLE logs_with_projections 
UPDATE 
    description = 'hello world'
WHERE subsystem = 'bd';


-- Для logs_with_projections_v2 
ALTER TABLE logs_with_projections_v2 
UPDATE 
    comment = 'two tee to two two'
WHERE timestamp = '2000-07-05 08:27:55';

ALTER TABLE logs_with_projections_v2 
UPDATE 
    description = 'hello world'
WHERE subsystem = 'bd';


-- Для logs_with_projections_v3 и logs_with_projections_metadata
ALTER TABLE logs_with_projections_metadata 
UPDATE 
    comment = 'two tee to two two'
WHERE log_id IN (
    SELECT log_id 
    FROM logs_with_projections_v3 
    WHERE timestamp = '2000-07-05 08:27:55'
);

ALTER TABLE logs_with_projections_metadata 
UPDATE 
    description = 'hello world'
WHERE log_id IN (
    SELECT log_id 
    FROM logs_with_projections_v3 
    WHERE subsystem = 'bd'
);


-- Оптимизация таблиц
OPTIMIZE TABLE logs_with_projections FINAL;
OPTIMIZE TABLE logs_with_projections_v2 FINAL;
OPTIMIZE TABLE logs_with_projections_v3 FINAL;
OPTIMIZE TABLE logs_with_projections_metadata FINAL;


INSERT INTO test_update
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
AND query LIKE 'ALTER TABLE %'

INSERT INTO test_update
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
AND query LIKE 'OPTIMIZE TABLE %'

