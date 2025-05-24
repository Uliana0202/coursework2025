# Организация подсистемы ведения журналов событий с использованием СУБД Clickhouse

## Папка data
### Генератор тестовых логов событий (generate_data.py)
Генератор синтетических логов событий для тестирования и разработки систем аналитики. Создает CSV-файл с реалистичными данными о действиях пользователей в информационной системе.

#### 🔍 Особенности
- Генерация разнообразных событий (логины, операции с данными, системные события)
- Реалистичные временные метки в заданном диапазоне
- Согласованные комментарии и описания событий
- Гибкая настройка через конфигурационные параметры
  
#### ⚙️ Конфигурация
```
# Конфигурация генератора
NUM_RECORDS = 3000  # Количество записей
START_DATE = datetime(2000, 1, 1)  # Начальная дата
END_DATE = datetime(2024, 12, 31)  # Конечная дата
CSV_FILE = 'logs_data_3_000.csv'  # Имя выходного файла
```

#### 📂 Структура данных
Поле         |	Тип	    |Описание
-------------|----------|---------------------------------|
timestamp	   |datetime	|Временная метка события
login        |string	  |Email пользователя
event	       |string	  |Тип события (например, 'login')
subsystem	   |string	  |Подсистема, где произошло событие
comment      |string	  |Текст комментария
description  |string    |Подробное описание события

#### 🛠 Техническая реализация
Основные функции генератора:
- generate_logins() - создает список уникальных email-адресов пользователей
- generate_events() - генерирует 100 различных типов событий
- generate_subsystems() - создает список подсистем системы
- generate_comments() - формирует осмысленные комментарии к событиям
- generate_descriptions() - генерирует описания для каждого типа события
- random_timestamp() - создает случайную временную метку в заданном диапазоне

#### 📊 Пример данных
```
timestamp,login,event,subsystem,comment,description
2021-05-12 14:32:45,user42@gmail.com,login_success,auth,"User user42@gmail.com performed login_success in auth","Successful completion of login"
2020-11-03 09:12:22,user17@company.org,export_complete,reporting_backend,"Action export_complete completed successfully in reporting_backend","System event: export_complete"
```

## Папка queries_select
###  Модуль generate_select_query.py
SQL-запросов на основе комбинаторики атрибутов. Генерирует все возможные комбинации условий WHERE для анализа логов.

#### 🔍 Особенности
- Генерация полного набора комбинаций - создает все возможные сочетания условий (от одиночных до полного набора атрибутов)
- Динамическое построение WHERE-клауз - автоматически формирует условия фильтрации
- Случайные логические операторы - использует случайный выбор между AND/OR для соединения условий
- Гибкие шаблоны условий - поддерживает разные типы SQL-условий (LIKE, сравнение дат)
- Экспорт результатов - сохраняет сгенерированные запросы в файл queries.txt

#### ⚙️ Конфигурация
```
attributes = {
    'timestamp': "timestamp <= '2012-11-21'",  # Фильтр по дате
    'login': "login LIKE 'user10%'",          # Фильтр по пользователям
    'event': "event LIKE 'session%'",         # Фильтр по событиям
    'subsystem': "subsystem LIKE 'b%'"        # Фильтр по подсистемам
}
```
#### 🛠 Техническая реализация
1. Генерирует все возможные комбинации атрибутов (от 1 до 4 в данном случае)
2. Для каждой комбинации:
  - Создает список условий WHERE
  - Случайно выбирает операторы AND/OR между условиями
  - Формирует итоговый SQL-запрос
3. Сохраняет все запросы в файл queries.txt
4. Выводит запросы в консоль с нумерацией

#### 📊 Пример генерируемых запросов
```
-- Одиночное условие
SELECT count(*) FROM table_name WHERE subsystem LIKE 'b%';

-- Комбинация условий с AND
SELECT count(*) FROM table_name WHERE login LIKE 'user10%' AND event LIKE 'session%';
```

##  Модуль generate_select_query.py

#### 🔍 Особенности
- Сравнительный анализ производительности между разными типами таблиц:
  - logs_full_scan - таблица без оптимизаций
  - logs_ordered - таблица с правильным порядком сортировки
  - logs_with_indexes - таблица с индексами
  - logs_with_projections - таблица с проекциями
- Устойчивость к перегрузкам - автоматические повторы при перегрузке CPU
- Детальный сбор метрик:
  - Время выполнения
  - Прочитанные строки и байты
  - Использование памяти
  - Использование проекций и представлений
- Визуализация результатов через табличное представление
  
#### ⚙️ Конфигурация
```
# Подключение к ClickHouse
client = Client(
    host='localhost',
    user='default',
    password='',
    database='course_db'
)

# Тестируемые таблицы
log_tables = ['logs_full_scan', 'logs_ordered', 'logs_with_indexes', 'logs_with_projections']

# Загрузка тестовых запросов
with open('queries_select/queries_and_2.txt', 'r') as f:
    queries = [(line.strip(), f"query_{idx}") for idx, line in enumerate(f.readlines(), 1)]
```

#### 🛠 Техническая реализация
1. Загружает набор тестовых запросов из файла
2. Для каждого запроса:
  - Выполняет на всех тестовых таблицах
  - Собирает метрики из system.query_log
  - Сохраняет результаты в таблицу test_select_query
  - Выводит сводную таблицу с метриками
3. При перегрузке CPU:
  - Автоматически делает паузу
  - Увеличивает интервал между повторами
  - Максимум 3 попытки выполнения

#### 📊 Пример вывода
```
==================================================
Running benchmark for query type: query_1
Query condition: timestamp BETWEEN '2007-11-21' AND '2025-11-21'
==================================================

Executing query on logs_with_indexes_v2:
SELECT count(*) FROM logs_with_indexes_v2 WHERE timestamp BETWEEN '2007-11-21' AND '2025-11-21'
Result count: 34132

Successfully inserted query log data into test_select_query table

+------------------------------------+-------------------------------------------------------------------------------------------------+---------------------+-----------------+-------------+--------------+----------------+-------------------------------------------------------------+---------+
| Table                              | Query Text                                                                                      | Execution Time      |   Duration (ms) |   Rows Read |   Bytes Read |   Memory Usage | Projections                                                 | Views   |
+====================================+=================================================================================================+=====================+=================+=============+==============+================+=============================================================+=========+
| ['course_db.logs_with_indexes_v2'] | SELECT count(*) FROM logs_with_indexes_v2 WHERE timestamp BETWEEN '2007-11-21' AND '2025-11-21' | 2025-05-24 16:32:49 |             373 |        8193 |        32784 |          45024 | ['course_db.logs_with_indexes_v2._minmax_count_projection'] | []      |
+------------------------------------+-------------------------------------------------------------------------------------------------+---------------------+-----------------+-------------+--------------+----------------+-------------------------------------------------------------+---------+

```

## Модуль insert_queries.py
Модуль для тестирования производительности различных методов вставки данных в ClickHouse.

#### 🔍 Особенности
- Сравнение 4 методов вставки:
  - Одиночные вставки (single)
  - Пакетная вставка (bulk)
  - Вставка через буферную таблицу (buffer)
  - Вставка в Native-формате (native)
- Автоматический сбор метрик:
  - Время выполнения
  - Скорость вставки (строк/сек)
  - Автоматическое сохранение результатов в CSV
- Устойчивость к перегрузкам с экспоненциальной задержкой
- Поддержка больших объемов данных (тестировалось на 3000+ записей)
  
#### ⚙️ Конфигурация
```
# Подключение к ClickHouse
client = Client(
    host='localhost',
    user='default',
    password='',
    database='course_db'
)

# Поддерживаемые методы вставки (можно включать/отключать в main())
TEST_METHODS = {
    'single': insert_single,
    'bulk': insert_bulk,
    'buffer': insert_buffer,
    'native': insert_native
}
```

#### 🛠 Техническая реализация
1. Одиночная вставка (insert_single)
  - Вставляет данные построчно
  - Референсный метод для сравнения производительности
  - Наихудшая производительность
2. Пакетная вставка (insert_bulk)
  - Вставляет все данные одним запросом
  - Оптимальный баланс между простотой и производительностью
3. Буферная вставка (insert_buffer)
  - Использует буферную таблицу ClickHouse
  - Данные сначала попадают в буфер, затем фоново переносятся
  - Требует дополнительной настройки таблиц
4. Native-формат (insert_native)
  - Использует бинарный формат ClickHouse
  - Максимальная производительность
  - Требует преобразования данных
    
#### 📊 Пример данных
```
Loaded 3000 rows from file
Starting Native format insertion...
Native insertion completed. Time: 0.87 sec

Performance test results:
native: 0.87 sec (3448 rows/sec)

Results saved to insertion_results.csv
```

##  Модуль insert_simulator.py
Cимулятор нагрузки для тестирования вставки данных в ClickHouse с поддержкой многопоточной работы и пула соединений.

#### 🔍 Особенности
- Реалистичное моделирование нагрузки:
  - Переменный размер пакетов (100-1000 записей)
  - Случайные интервалы между вставками (0.1-5 сек)
  - Настраиваемая длительность теста
- Многопоточная архитектура:
  - Пул worker-потоков для параллельной вставки
  - Очередь задач с ограниченным размером
  - Пул соединений к ClickHouse
- Отказоустойчивость:
  - Автоматические повторы при ошибках
  - Экспоненциальная задержка при перегрузках
  - Контроль таймаутов соединений
- Мониторинг производительности:
  - Логирование скорости вставки (записей/сек)
  - Детальное логирование всех операций
- Поддержка Native-формата ClickHouse
  
#### ⚙️ Конфигурация
```
CONFIG = {
    'ch_config': {  # Параметры подключения к ClickHouse
        'host': 'localhost',
        'user': 'default',
        'password': '',
        'database': 'course_db',
        'settings': {
            'max_execution_time': 30,
            'use_native_format': True  # Использование бинарного формата
        }
    },
    'log_file': 'data/logs_data_3_000.csv',  # Источник данных
    'target_table': 'logs_insert_test',      # Целевая таблица
    'duration_minutes': 2,                   # Длительность теста
    'min_batch_size': 100,                   # Минимальный размер пакета
    'max_batch_size': 1000,                  # Максимальный размер пакета
    'min_delay_sec': 0.1,                    # Минимальная задержка
    'max_delay_sec': 5.0,                    # Максимальная задержка
    'workers_count': 3,                      # Количество worker-потоков
    'max_queue_size': 10000                  # Макс. размер очереди задач
}
```

#### 🛠 Техническая реализация
![img1](https://github.com/user-attachments/assets/a366316e-46b8-481d-bdba-f5d3c7326a16)

#### 📊 Пример вывода
```
2023-05-15 14:30:22,123 - INFO - Starting log simulation...
2023-05-15 14:30:23,456 - INFO - Inserted 342 logs in 0.45s (760.0 logs/sec)
2023-05-15 14:30:25,789 - WARNING - CPU overload detected, retrying in 5 seconds
2023-05-15 14:31:22,123 - INFO - Simulation completed
```

##  Папка skripts
### Модуль select_optimization.sql
SQL-скрипт для создания и оптимизации таблиц ClickHouse с различными подходами к ускорению запросов.

#### 🔍 Особенности
- 4 стратегии оптимизации в одной схеме:
  - logs_full_scan - базовая таблица без оптимизаций
  - logs_ordered - оптимизация через первичный ключ
  - logs_with_indexes - использование индексов гранул
  - logs_with_projections - применение проекций
  - logs_partitioned - партиционирование по времени
- Поддержка всех основных методов ускорения ClickHouse:
  - Первичные ключи (ORDER BY)
  - Индексы пропуска (Bloom Filter)
  - Проекции (Projections)
  - Партиционирование
  - 
#### 🛠 Техническая реализация
1. logs_full_scan
```
CREATE TABLE logs_full_scan (
    ...
) ENGINE = MergeTree()
ORDER BY tuple();  -- Явное указание отсутствия сортировки
```
Назначение: Контрольная таблица для сравнения производительности

2. logs_ordered
```
CREATE TABLE logs_ordered (
    ...
) ENGINE = MergeTree()
ORDER BY (timestamp, login, event, subsystem);
```
Оптимизация:
- Упорядочивание данных по часто используемым полям
- Ускорение запросов с фильтрацией по этим полям

3. logs_with_indexes
```
CREATE TABLE logs_with_indexes (
    ...
) ENGINE = MergeTree()
ORDER BY (timestamp)
SETTINGS index_granularity = 8192;

-- Добавление индексов Bloom Filter
ALTER TABLE logs_with_indexes
    ADD INDEX login_index login TYPE bloom_filter GRANULARITY 4;
```
Оптимизация:
- Индексы пропуска для ускорения фильтрации
- Настройка гранулярности индексов

4. logs_with_projections
```
CREATE TABLE logs_with_projections (
    ...
) ENGINE = MergeTree()
ORDER BY (timestamp)
SETTINGS allow_experimental_projection_optimization = 1;

-- Добавление проекции
ALTER TABLE logs_with_projections
ADD PROJECTION login_projection (
    SELECT * ORDER BY (login, timestamp)
);
```
Оптимизация:
- Альтернативная физическая сортировка данных
- Автоматическое использование оптимизатором

5. logs_partitioned
```
CREATE TABLE logs_partitioned (
    ...
) ENGINE = MergeTree()
PARTITION BY toYear(timestamp) * 10 + (toMonth(timestamp) > 6)
ORDER BY (login, event, subsystem);
```
Оптимизация:
- Партиционирование по полугодиям
- Ускорение временных запросов

###  Модуль test_select.sql
Скрипт для создания и анализа таблицы с метриками выполнения тестовых запросов в ClickHouse.

#### 🔍 Особенности
- Создание специализированной таблицы для хранения:
  - Статистики выполнения запросов
  - Использования ресурсов
  - Применения проекций и представлений
- Готовые аналитические запросы для сравнения:
  - Производительности разных таблиц
  - Эффективности различных типов запросов
- Гибкая фильтрация по типам запросов
  
#### 📂 Структура данных
Структура таблицы test_select_query
Поле	       | Тип данных|	Описание
-------------|----------|---------------------------------|
tables	|Array(String)	|Список задействованных таблиц
query	|String	|Текст выполненного запроса
event_time	|DateTime |	Время выполнения запроса
query_duration_ms	|UInt64	|Длительность выполнения (мс)
read_rows	|UInt64|	Прочитано строк
read_bytes	|UInt64|	Прочитано байт
memory_usage	|UInt64|	Использовано памяти (байт)
projections	|Array(String)|	Использованные проекции
views	|Array(String)|	Использованные представления

#### 🛠 Техническая реализация
Примеры аналитических запросов

Общая статистика по всем таблицам:
```
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
```

Фильтрация по типу запросов:
```
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
    query NOT LIKE '%subsystem%'
GROUP BY tables
ORDER BY total_duration_ms;
```
#### 📊 Пример данных
![image](https://github.com/user-attachments/assets/8ef7b53e-bc7e-40b1-a2b5-457cddc1212f)

###  Модуль test_view.sql
Скрипт для тестирования и сравнения производительности материализованных представлений на разных типах таблиц в ClickHouse.

#### 🔍 Особенности
- Создание материализованного представления для хранения неудачных событий
- Сравнение производительности на 5 типах таблиц:
    - logs_full_scan (без оптимизаций)
    - logs_ordered (с сортировкой)
    - logs_with_indexes (с индексами)
    - logs_with_projections (с проекциями)
    - logs_partitioned (с партиционированием)
- Сбор метрик выполнения в таблицу test_view
- Анализ лога запросов из system.query_log
  
#### 🛠 Техническая реализация
1. Материализованное представление failed_events_mv
```
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
```
Назначение: Хранение и быстрый доступ к событиям с ошибками

2. Таблица для сбора метрик test_view
```
CREATE TABLE test_view (
    tables Array(String),
    query String,
    event_time DateTime,
    query_duration_ms UInt64,
    read_rows UInt64,
    read_bytes UInt64,
    memory_usage UInt64,
    projections Array(String),
    views Array(String)
) ENGINE = MergeTree
ORDER BY event_time;
```

3. Сравнительные запросы
```
-- Для каждой тестовой таблицы
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM logs_ordered  -- или logs_full_scan, logs_with_indexes и т.д.
WHERE event LIKE '%_failed'
ORDER BY timestamp DESC;
```

#### 📊 Пример данных
![image](https://github.com/user-attachments/assets/3fcc1ecd-4037-4ea1-a4a2-b8a65e303c96)

###  Модуль test_partitioned.sql
Скрипт для тестирования производительности партиционированных таблиц в ClickHouse и сравнения с другими методами оптимизации.

#### 🔍 Особенности
- Сравнение 5 стратегий хранения данных:
  - logs_full_scan - без оптимизаций
  - logs_ordered - с сортировкой по timestamp
  - logs_with_indexes - с индексами гранул
  - logs_with_projections - с проекциями
  - logs_partitioned - с партиционированием по времени
- Фокус на временных запросах с фильтрацией по диапазону дат
- Сбор метрик производительности в таблицу test_partitioned
- Анализ лога запросов для объективного сравнения
  
#### 🛠 Техническая реализация
1. Таблица для сбора метрик test_partitioned
```
CREATE TABLE test_partitioned (
    tables Array(String),
    query String,
    event_time DateTime,
    query_duration_ms UInt64,
    read_rows UInt64,
    read_bytes UInt64,
    memory_usage UInt64,
    projections Array(String),
    views Array(String)
ENGINE = MergeTree
ORDER BY event_time
SETTINGS index_granularity = 8192;
```
2. Тестовые запросы с временным фильтром
```
SELECT 
    timestamp,
    login,
    event,
    subsystem,
    comment
FROM logs_partitioned  -- или другие таблицы
WHERE timestamp BETWEEN '2013-01-16 20:19:58' AND '2014-04-16 20:19:58'
ORDER BY timestamp DESC;
```

3. Сбор статистики выполнения
```
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
```

4. Пример аналитики после выполнения:

```
SELECT 
    tables,
    avg(query_duration_ms) AS avg_time_ms,
    avg(read_rows) AS avg_rows_read,
    avg(read_bytes) AS avg_bytes_read
FROM test_partitioned
GROUP BY tables
ORDER BY avg_time_ms;
```

#### 📊 Пример данных
![image](https://github.com/user-attachments/assets/b331a74c-fe48-4960-9789-30d0170e2f27)



###  Модуль test_insert.sql
Скрипт для тестирования различных методов вставки данных в ClickHouse, включая использование буферных таблиц.

#### 🔍 Особенности
- Создание тестовой таблицы logs_insert_test с оптимальной структурой:
  - LowCardinality для строковых полей с малым количеством уникальных значений
  - Сортировка по часто используемым полям (timestamp, login, event, subsystem)
- Реализация буферной таблицы logs_buffer с настраиваемыми параметрами:
  - Контролируемые задержки перед сбросом данных
  - Настраиваемые пороги по количеству строк и объему данных
-Примеры вставки данных для тестирования производительности

#### 🛠 Техническая реализация
Основная таблица logs_insert_test
```
CREATE TABLE logs_insert_test (
    timestamp DateTime,
    login LowCardinality(String),
    event LowCardinality(String),
    subsystem LowCardinality(String),
    comment String,
    description String
) ENGINE = MergeTree()
ORDER BY (timestamp, login, event, subsystem);
```
Оптимизации:
- LowCardinality для эффективного хранения повторяющихся значений
- Оптимальный ORDER BY для ускорения типовых запросов

Буферная таблица logs_buffer
```
CREATE TABLE logs_buffer AS logs_insert_test
ENGINE = Buffer(
    'default', 
    'logs_insert_test',
    1,       -- Количество уровней буферизации
    5,       -- Минимальная задержка (сек)
    10,      -- Максимальная задержка (сек)
    100,     -- Минимальное количество строк
    10000,   -- Максимальное количество строк
    10000,   -- Минимальный размер (байт)
    100000   -- Максимальный размер (байт)
);
```
Назначение: Буферизация вставок для снижения нагрузки на сервер

###  Модуль update_optimization_projection.sql
Скрипт для оптимизации структуры таблиц с использованием проекций в ClickHouse, включая продвинутые техники разделения данных.

#### 🔍 Особенности
- Две стратегии оптимизации:
  - Улучшенная версия таблицы с проекциями (logs_with_projections_v2)
  - Разделение на неизменяемые данные и метаданные (logs_with_projections_v3 + logs_with_projections_metadata)
- Поддержка экспериментальных возможностей ClickHouse:
  - deduplicate_merge_projection_mode = 'rebuild'
  - allow_experimental_projection_optimization = 1
- Автоматическая материализация проекций для существующих данных

#### 🛠 Техническая реализация
1. Версия 2: Улучшенная таблица с проекциями
```
CREATE TABLE logs_with_projections_v2 (
    ...
) ENGINE = ReplacingMergeTree()
ORDER BY (timestamp)
SETTINGS 
    deduplicate_merge_projection_mode = 'rebuild',
    index_granularity = 8192;

-- Проекция для поиска по login
ALTER TABLE logs_with_projections_v2
ADD PROJECTION login_projection_v2 (
    SELECT * ORDER BY (login, timestamp)
);
```
Улучшения:
- Использование ReplacingMergeTree для дедупликации
- Настройка перестроения проекций при слиянии

2. Версия 3: Разделение данных и метаданных
```
-- Основные данные (неизменяемые)
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
ORDER BY (timestamp);

-- Метаданные (изменяемые)
CREATE TABLE logs_with_projections_metadata (
    log_id UUID,
    comment String,
    description String
) ENGINE = ReplacingMergeTree()
ORDER BY (log_id);
```
Преимущества:
- Разделение часто и редко изменяемых данных
- Сохранение возможности обновления метаданных
- Эффективное использование проекций для основных данных

Миграция данных
```
-- Перенос в улучшенную таблицу
INSERT INTO logs_with_projections_v2 
SELECT * FROM logs_with_projections;

-- Перенос в раздельную структуру
INSERT INTO logs_with_projections_v3 (...)
SELECT ... FROM logs_with_projections;

INSERT INTO logs_with_projections_metadata
SELECT ... FROM logs_with_projections
JOIN logs_with_projections_v3 ...;
```


###  Модуль update_optimization_indexed.sql
Скрипт для оптимизации таблиц с индексами в ClickHouse, включая улучшенные версии индексов и разделение данных.

#### 🔍 Особенности
- Две стратегии оптимизации:
  - Улучшенная версия таблицы с индексами (logs_with_indexes_v2)
  - Разделение на основные данные и метаданные (logs_with_indexes_v3 + logs_with_indexes_metadata)
- Оптимизированные индексы пропускания:
  - Bloom Filter с настраиваемой гранулярностью
  - Полная материализация индексов
- Поддержка версионирования через ReplacingMergeTree

#### 🛠 Техническая реализация
1. Версия 2: Улучшенная таблица с индексами
```
CREATE TABLE logs_with_indexes_v2 (
    ...
) ENGINE = ReplacingMergeTree()
ORDER BY (timestamp)
SETTINGS index_granularity = 8192;

-- Индексы Bloom Filter
ALTER TABLE logs_with_indexes_v2
    ADD INDEX login_index_v2 login TYPE bloom_filter GRANULARITY 4;
```
Улучшения:
- Оптимизированные Bloom Filter индексы (гранулярность 4)
- Поддержка версионирования данных

2. Версия 3: Разделение данных и метаданных
```
-- Основные данные
CREATE TABLE logs_with_indexes_v3 (
    log_id UUID,
    timestamp DateTime,
    login LowCardinality(String),
    event LowCardinality(String),
    subsystem LowCardinality(String)
) ENGINE = MergeTree()
ORDER BY (timestamp);

-- Метаданные
CREATE TABLE logs_with_indexes_metadata (
    log_id UUID,
    comment String,
    description String
) ENGINE = ReplacingMergeTree()
ORDER BY (log_id);
```
Преимущества:
- Разделение часто и редко изменяемых данных
- Возможность обновления метаданных без перестроения индексов
- Более эффективное использование индексов для основных данных

Миграция данных
```
-- Перенос в улучшенную таблицу
INSERT INTO logs_with_indexes_v2 
SELECT * FROM logs_with_indexes;

-- Перенос в раздельную структуру
INSERT INTO logs_with_indexes_v3 (...)
SELECT ... FROM logs_with_indexes;

INSERT INTO logs_with_indexes_metadata
SELECT ... FROM logs_with_indexes
JOIN logs_with_indexes_v3 ...;
```

###  Модуль test_update.sql
Скрипт для тестирования производительности операций UPDATE в ClickHouse на различных типах таблиц с последующим сбором метрик.

#### 🔍 Особенности
- Сравнение производительности UPDATE на 6 типах таблиц:
  - Базовые таблицы (logs_with_indexes, logs_with_projections)
  - Оптимизированные версии (_v2)
  - Раздельные структуры (_v3 + _metadata)
- Тестирование разных сценариев обновления:
  - Обновление по временной метке
  - Обновление по подсистеме
- Автоматический сбор метрик:
  - Время выполнения
  - Использование ресурсов
  - Затронутые строки
- Оптимизация таблиц после обновления

#### 🛠 Техническая реализация
Примеры тестовых запросов
```
-- Обновление в таблице с индексами
ALTER TABLE logs_with_indexes 
UPDATE comment = 'two tee to two two'
WHERE subsystem = '2000-07-05 08:27:55';

-- Обновление в раздельной структуре (только метаданные)
ALTER TABLE logs_with_indexes_metadata 
UPDATE comment = 'two tee to two two'
WHERE log_id IN (SELECT log_id FROM logs_with_indexes_v3 WHERE timestamp = '2000-07-05 08:27:55');
```
Сбор метрик
```
-- Сбор статистики по UPDATE
INSERT INTO test_update
SELECT * FROM system.query_log
WHERE query_duration_ms > 0
AND query LIKE 'ALTER TABLE %';

-- Сбор статистики по OPTIMIZE
INSERT INTO test_update
SELECT * FROM system.query_log
WHERE query_duration_ms > 0
AND query LIKE 'OPTIMIZE TABLE %';
```

Анализ результатов
Пример запроса для сравнения производительности:
```
SELECT 
    tables,
    avg(query_duration_ms) AS avg_update_time,
    avg(read_rows) AS avg_rows_read,
    avg(memory_usage) AS avg_memory
FROM test_update
WHERE query LIKE 'ALTER TABLE%'
GROUP BY tables
ORDER BY avg_update_time;
```

###  Модуль update_optimization_projection.sql

#### 🔍 Особенности


#### 🛠 Техническая реализация


