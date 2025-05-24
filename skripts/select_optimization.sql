use course_db;

CREATE TABLE logs_full_scan (
    timestamp DateTime,
    login LowCardinality(String),       -- ~1000 уникальных значений
    event LowCardinality(String),       -- ~100 уникальных значений
    subsystem LowCardinality(String),   -- ~20 уникальных значений
    comment String,
    description String
) ENGINE = MergeTree()
ORDER BY tuple();

ALTER TABLE course_db.logs_with_indexes DELETE WHERE 1 = 1;


-- Оптимизация через ORDER BY (первичный ключ)
CREATE TABLE logs_ordered (
    timestamp DateTime,
    login LowCardinality(String),
    event LowCardinality(String),
    subsystem LowCardinality(String),
    comment String,
    description String
) ENGINE = MergeTree()
ORDER BY (timestamp, login, event, subsystem);


-- Оптимизация с помощью индексов гранул
CREATE TABLE logs_with_indexes (
    timestamp DateTime,
    login LowCardinality(String),
    event LowCardinality(String),
    subsystem LowCardinality(String),
    comment String,
    description String
) ENGINE = MergeTree()
ORDER BY (timestamp)
SETTINGS index_granularity = 8192;

-- Добавляем индексы пропускания
ALTER TABLE logs_with_indexes
    ADD INDEX login_index login TYPE bloom_filter GRANULARITY 4;

ALTER TABLE logs_with_indexes
    ADD INDEX event_index event TYPE bloom_filter GRANULARITY 4;

ALTER TABLE logs_with_indexes
    ADD INDEX subsystem_index subsystem TYPE bloom_filter GRANULARITY 4;

-- Материализуем индексы
ALTER TABLE logs_with_indexes MATERIALIZE INDEX login_index;
ALTER TABLE logs_with_indexes MATERIALIZE INDEX event_index;
ALTER TABLE logs_with_indexes MATERIALIZE INDEX subsystem_index;


-- Таблица с проекциями
CREATE TABLE logs_with_projections (
    timestamp DateTime,
    login LowCardinality(String),
    event LowCardinality(String),
    subsystem LowCardinality(String),
    comment String,
    description String
) ENGINE = MergeTree()
ORDER BY (timestamp)
SETTINGS allow_experimental_projection_optimization = 1;


ALTER TABLE logs_with_projections
ADD PROJECTION login_projection (
    SELECT * ORDER BY (login, timestamp)
);

-- Для существующих данных
ALTER TABLE logs_with_projections MATERIALIZE PROJECTION login_projection;


--Таблица партиционированная
CREATE TABLE logs_partitioned (
    timestamp DateTime,
    login LowCardinality(String),
    event LowCardinality(String),
    subsystem LowCardinality(String),
    comment String,
    description String
) ENGINE = MergeTree()
PARTITION BY toYear(timestamp) * 10 + (toMonth(timestamp) > 6)
ORDER BY (login, event, subsystem);


