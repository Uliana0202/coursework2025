use course_db;

DROP TABLE IF EXISTS logs_with_indexes_metadata;


-- ReplacingMergeTree с версионированием
CREATE TABLE logs_with_indexes_v2 (
    timestamp DateTime,
    login LowCardinality(String),
    event LowCardinality(String),
    subsystem LowCardinality(String),
    comment String,
    description String
) ENGINE = ReplacingMergeTree()
ORDER BY (timestamp)
SETTINGS index_granularity = 8192;

-- Добавляем индексы пропускания
ALTER TABLE logs_with_indexes_v2
    ADD INDEX login_index_v2 login TYPE bloom_filter GRANULARITY 4;

ALTER TABLE logs_with_indexes_v2
    ADD INDEX event_index_v2 event TYPE bloom_filter GRANULARITY 4;

ALTER TABLE logs_with_indexes_v2
    ADD INDEX subsystem_index_v2 subsystem TYPE bloom_filter GRANULARITY 4;


INSERT INTO logs_with_indexes_v2 (timestamp, login, event, subsystem, comment, description)
SELECT * FROM logs_with_indexes;

-- Материализуем индексы
ALTER TABLE logs_with_indexes_v2 MATERIALIZE INDEX login_index_v2;
ALTER TABLE logs_with_indexes_v2 MATERIALIZE INDEX event_index_v2;
ALTER TABLE logs_with_indexes_v2 MATERIALIZE INDEX subsystem_index_v2;




-- Раздельная таблица метаданных
CREATE TABLE logs_with_indexes_v3 (
    log_id UUID,
    timestamp DateTime,
    login LowCardinality(String),
    event LowCardinality(String),
    subsystem LowCardinality(String)
) ENGINE = MergeTree()
ORDER BY (timestamp);


CREATE TABLE logs_with_indexes_metadata (
    log_id UUID DEFAULT generateUUIDv4(),
    timestamp DateTime,
    comment String,
    description String,
) ENGINE = ReplacingMergeTree()
ORDER BY (log_id);

-- Добавляем индексы пропускания
ALTER TABLE logs_with_indexes_v3
    ADD INDEX login_index_v3 login TYPE bloom_filter GRANULARITY 4;

ALTER TABLE logs_with_indexes_v3
    ADD INDEX event_index_v3 event TYPE bloom_filter GRANULARITY 4;

ALTER TABLE logs_with_indexes_v3
    ADD INDEX subsystem_index_v3 subsystem TYPE bloom_filter GRANULARITY 4;


INSERT INTO logs_with_indexes_v3  (log_id, timestamp, login, event, subsystem)
SELECT 
    generateUUIDv4() as log_id,
    timestamp,
    login,
    event,
    subsystem
FROM logs_with_indexes;

INSERT INTO logs_with_indexes_metadata (log_id, comment, description)
SELECT 
    m.log_id,
    l.comment,
    l.description
FROM logs_with_indexes l
JOIN logs_with_indexes_v3  m ON 
    l.timestamp = m.timestamp AND 
    l.login = m.login AND 
    l.event = m.event AND 
    l.subsystem = m.subsystem;

-- Материализуем индексы
ALTER TABLE logs_with_indexes_v3 MATERIALIZE INDEX login_index_v3;
ALTER TABLE logs_with_indexes_v3 MATERIALIZE INDEX event_index_v3;
ALTER TABLE logs_with_indexes_v3 MATERIALIZE INDEX subsystem_index_v3;
