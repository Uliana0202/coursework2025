use course_db;

DROP TABLE IF EXISTS logs_with_projections;

-- Создаем новую версию таблицы с проекциями
CREATE TABLE logs_with_projections_v2 (
    timestamp DateTime,
    login LowCardinality(String),
    event LowCardinality(String),
    subsystem LowCardinality(String),
    comment String,
    description String
) ENGINE = ReplacingMergeTree()
ORDER BY (timestamp)
SETTINGS 
    deduplicate_merge_projection_mode = 'rebuild',
    index_granularity = 8192;

-- Добавляем проекцию для поиска по login
ALTER TABLE logs_with_projections_v2
ADD PROJECTION login_projection_v2 (
    SELECT *
    ORDER BY (login, timestamp)
);

-- Материализуем проекции для существующих данных
ALTER TABLE logs_with_projections_v2 MATERIALIZE PROJECTION login_projection_v2;


-- Перенос данных из старой таблицы
INSERT INTO logs_with_projections_v2 
    (timestamp, login, event, subsystem, comment, description)
SELECT 
    timestamp, login, event, subsystem, comment, description 
FROM logs_with_projections;

-- Материализуем проекции для существующих данных
ALTER TABLE logs_with_projections_v2 MATERIALIZE PROJECTION login_projection_v2;


-- Раздельная таблица метаданных
CREATE TABLE logs_with_projections_v3 (
    log_id UUID DEFAULT generateUUIDv4(),
    timestamp DateTime,
    login LowCardinality(String),
    event LowCardinality(String),
    subsystem LowCardinality(String),
    PROJECTION login_projection (
        SELECT * ORDER BY (login, timestamp)
    )
) ENGINE = MergeTree()
ORDER BY (timestamp)
SETTINGS allow_experimental_projection_optimization = 1;

-- Таблица метаданных (изменяемые данные) с поддержкой проекций
CREATE TABLE logs_with_projections_metadata (
    log_id UUID,
    comment String,
    description String,
) ENGINE = ReplacingMergeTree()
ORDER BY (log_id)
SETTINGS 
    deduplicate_merge_projection_mode = 'rebuild',
    allow_experimental_projection_optimization = 1;


INSERT INTO logs_with_projections_v3  (log_id, timestamp, login, event, subsystem)
SELECT 
    generateUUIDv4() as log_id,
    timestamp,
    login,
    event,
    subsystem
FROM logs_with_projections;

INSERT INTO logs_with_projections_metadata (log_id, comment, description)
SELECT 
    m.log_id,
    l.comment,
    l.description
FROM logs_with_projections l
JOIN logs_with_projections_v3  m ON 
    l.timestamp = m.timestamp AND 
    l.login = m.login AND 
    l.event = m.event AND 
    l.subsystem = m.subsystem;

