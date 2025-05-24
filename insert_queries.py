from clickhouse_driver import Client
import time
import csv
from datetime import datetime
from time import sleep

client = Client(
    host='localhost',
    user='default',
    password='',
    database='course_db'
)

def read_csv_file(file_path):
    data = []
    with open(file_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            timestamp = datetime.strptime(row['timestamp'], '%Y-%m-%d %H:%M:%S')

            data.append({
                'timestamp': timestamp,
                'login': row['login'],
                'event': row['event'],
                'subsystem': row['subsystem'],
                'comment': row['comment'],
                'description': row['description']
            })
    return data

def execute_with_retry(query, params=None, max_retries=3, initial_retry_delay=5):
    retry_delay = initial_retry_delay
    for attempt in range(max_retries):
        try:
            return client.execute(query, params) if params else client.execute(query)
        except Exception as e:
            if "CPU is overloaded" in str(e) and attempt < max_retries - 1:
                print(f"CPU overload detected, retrying in {retry_delay} seconds (attempt {attempt + 1}/{max_retries})")
                sleep(retry_delay)
                retry_delay *= 2
                continue
            raise e
    return None

def insert_single(data):
    print("Starting single-row insertion...")
    start = time.time()

    for row in data:
        execute_with_retry(
            "INSERT INTO logs_insert_test VALUES",
            [row]
        )

    duration = time.time() - start
    print(f"Single-row insertion completed. Time: {duration:.2f} sec")
    return duration

def insert_bulk(data):
    print("Starting bulk insertion...")
    start = time.time()

    execute_with_retry(
        "INSERT INTO logs_insert_test VALUES",
        data
    )

    duration = time.time() - start
    print(f"Bulk insertion completed. Time: {duration:.2f} sec")
    return duration

def insert_buffer(data):
    print("Starting buffer insertion...")
    start = time.time()

    execute_with_retry(
        "INSERT INTO logs_buffer VALUES",
        data
    )

    sleep(11)

    duration = time.time() - start
    print(f"Buffer insertion completed. Time: {duration:.2f} sec")
    return duration

def insert_native(data):
    print("Starting Native format insertion...")
    start = time.time()

    execute_with_retry(
        "INSERT INTO logs_insert_test FORMAT Native",
        data
    )

    duration = time.time() - start
    print(f"Native insertion completed. Time: {duration:.2f} sec")
    return duration

def save_results(results, data_length, filename='insertion_results.csv'):
    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Method', 'Time (sec)', 'Rows/sec'])
        for method, duration in results.items():
            writer.writerow([method, f"{duration:.2f}", f"{data_length/duration:.0f}"])
    print(f"\nResults saved to {filename}")

def main():
    data = read_csv_file('logs_data_3_000.csv')

    # Проверяем количество загруженных строк
    print(f"Loaded {len(data)} rows from file")

    results = {}

    # Тест 1: Одиночная вставка
    #results['single'] = insert_single(data)
    #client.execute("TRUNCATE TABLE logs_insert_test")

    # Тест 2: Пакетная вставка
    #results['bulk'] = insert_bulk(data)
    #client.execute("TRUNCATE TABLE logs_insert_test")

    # Тест 3: Вставка через буфер
    #results['buffer'] = insert_buffer(data)
    #client.execute("TRUNCATE TABLE logs_insert_test")

    # Тест 4: Вставка в Native-формате (новый метод)
    results['native'] = insert_native(data)
    client.execute("TRUNCATE TABLE logs_insert_test")


    # Вывод результатов
    print("\nPerformance test results:")
    for method, duration in results.items():
        rows_per_sec = len(data) / duration
        print(f"{method}: {duration:.2f} sec ({rows_per_sec:.0f} rows/sec)")

    save_results(results, len(data))


if __name__ == "__main__":
    main()