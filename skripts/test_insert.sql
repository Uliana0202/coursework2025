use course_db;

DROP TABLE IF EXISTS logs_buffer;
DROP TABLE IF EXISTS logs_insert_test;

CREATE TABLE logs_insert_test (
    timestamp DateTime,
    login LowCardinality(String),       -- ~1000 уникальных значений
    event LowCardinality(String),       -- ~100 уникальных значений
    subsystem LowCardinality(String),   -- ~20 уникальных значений
    comment String,
    description String
) ENGINE = MergeTree()
ORDER BY (timestamp, login, event, subsystem);

-- Буферная таблица
CREATE TABLE logs_buffer AS logs_insert_test
ENGINE = Buffer(
    'default', 
    'logs_insert_test',
    1,       -- Уменьшаем количество уровней
    5,       -- Минимальное время задержки (сек)
    10,      -- Максимальное время задержки
    100,     -- Минимальное количество строк (снижаем для теста)
    10000,   -- Максимальное количество строк
    10000,   -- Минимальный размер (байт) (снижаем)
    100000
);



TRUNCATE TABLE logs_insert_test;
TRUNCATE TABLE system.query_log;


DESCRIBE TABLE logs_buffer;
DESCRIBE TABLE logs_insert_test;

select count(*) from logs_insert_test;
select count(*) from logs_buffer;



INSERT INTO logs_buffer (timestamp, login, event, subsystem, comment, description)
VALUES
    ('2019-09-03 02:03:43', 'user771@yahoo.com', 'password_reset', 'reporting_backend', 'Unexpected behavior during password_reset', 'System event: password_reset'),
    ('2008-09-05 12:32:44', 'user226@outlook.com', 'backup_success', 'auth_v2', 'System recorded backup_success for subsystem auth_v2', 'Successful completion of backup'),
    ('2021-01-08 18:54:11', 'user332@domain.net', 'read_attempt', 'billing_new', 'User user332@domain.net performed read_attempt in billing_new', 'System event: read_attempt'),
    ('2024-12-07 00:07:58', 'user45@domain.net', 'create_complete', 'ui', 'Security-related action: create_complete', 'System event: create_complete');



