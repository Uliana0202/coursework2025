from clickhouse_driver import Client
from clickhouse_driver import errors as ch_errors
import time
import random
import csv
from datetime import datetime
import threading
import queue
import logging
from socket import error as socket_error
from time import sleep

# Настройка логирования
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('log_simulator.log'),
        logging.StreamHandler()
    ]
)


def execute_with_retry(conn, query, params=None, max_retries=3, initial_retry_delay=5):
    retry_delay = initial_retry_delay
    for attempt in range(max_retries):
        try:
            return conn.execute(query, params) if params else conn.execute(query)
        except Exception as e:
            if ("CPU is overloaded" in str(e) or
                "Timeout exceeded" in str(e)) and attempt < max_retries - 1:
                logging.warning(
                    f"Retryable error detected: {e}, retrying in {retry_delay} seconds (attempt {attempt + 1}/{max_retries})")
                sleep(retry_delay)
                retry_delay *= 2
                continue
            raise e
    return None


# Пул соединений для ClickHouse
class ConnectionPool:
    def __init__(self, config, size=5):
        self.config = config
        self.pool = queue.Queue(size)
        for _ in range(size):
            self.pool.put(self._create_connection())

    def _create_connection(self):
        return Client(**self.config)

    def get_connection(self):
        try:
            return self.pool.get(timeout=5)
        except queue.Empty:
            logging.warning("Connection pool exhausted, creating new connection")
            return self._create_connection()

    def return_connection(self, conn):
        try:
            self.pool.put(conn, timeout=5)
        except queue.Full:
            conn.disconnect()

    def close_all(self):
        while not self.pool.empty():
            conn = self.pool.get()
            conn.disconnect()


class LogSimulator:
    def __init__(self, config):
        self.config = config
        self.connection_pool = ConnectionPool(config['ch_config'], size=config['workers_count'] + 2)
        self.log_queue = queue.Queue(maxsize=config['max_queue_size'])
        self.running = False
        self.workers = []

    def read_logs(self):
        try:
            with open(self.config['log_file'], 'r') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    yield {
                        'timestamp': datetime.strptime(row['timestamp'], '%Y-%m-%d %H:%M:%S'),
                        'login': row['login'],
                        'event': row['event'],
                        'subsystem': row['subsystem'],
                        'comment': row['comment'],
                        'description': row['description']
                    }
        except Exception as e:
            logging.error(f"Error reading log file: {e}")
            raise

    # Поток-обработчик для вставки логов
    def worker(self):
        while self.running or not self.log_queue.empty():
            conn = None
            try:
                conn = self.connection_pool.get_connection()
                batch = self.log_queue.get(timeout=1)
                if batch:
                    self.insert_batch(conn, batch)
                    self.log_queue.task_done()
            except queue.Empty:
                continue
            except (socket_error, ch_errors.Error) as e:
                logging.warning(f"Connection error: {e}")
                if conn:
                    conn.disconnect()
                time.sleep(1)
            except Exception as e:
                logging.error(f"Worker error: {e}")
                time.sleep(1)
            finally:
                if conn:
                    self.connection_pool.return_connection(conn)

    def insert_batch(self, conn, batch):
        try:
            start_time = time.time()

            # Подготовка данных в column-oriented формате
            columns = [
                ('timestamp', [log['timestamp'] for log in batch]),
                ('login', [log['login'] for log in batch]),
                ('event', [log['event'] for log in batch]),
                ('subsystem', [log['subsystem'] for log in batch]),
                ('comment', [log['comment'] for log in batch]),
                ('description', [log['description'] for log in batch])
            ]

            # Формируем данные для вставки
            data = [tuple(col[1][i] for col in columns) for i in range(len(batch))]

            # Выполняем запрос с повторами при ошибках
            execute_with_retry(
                conn,
                f"INSERT INTO {self.config['target_table']} VALUES",
                data
            )

            elapsed = time.time() - start_time
            logging.info(f"Inserted {len(batch)} logs in {elapsed:.2f}s ({len(batch) / elapsed:.1f} logs/sec)")

        except Exception as e:
            logging.error(f"Insert failed after retries: {e}")
            raise

    def simulate_load(self):
        self.running = True

        # Запуск worker-ов
        for i in range(self.config['workers_count']):
            worker_thread = threading.Thread(
                target=self.worker,
                name=f"Worker-{i}",
                daemon=True
            )
            worker_thread.start()
            self.workers.append(worker_thread)

        # Генерация нагрузки
        log_generator = self.read_logs()
        end_time = time.time() + self.config['duration_minutes'] * 60

        while time.time() < end_time and self.running:
            try:
                batch_size = random.randint(
                    self.config['min_batch_size'],
                    self.config['max_batch_size']
                )

                batch = []
                for _ in range(batch_size):
                    try:
                        batch.append(next(log_generator))
                    except StopIteration:
                        log_generator = self.read_logs()
                        batch.append(next(log_generator))

                self.log_queue.put(batch, timeout=5)

                delay = random.uniform(
                    self.config['min_delay_sec'],
                    self.config['max_delay_sec']
                )
                time.sleep(delay)

            except queue.Full:
                logging.warning("Queue is full, waiting...")
                time.sleep(1)
            except Exception as e:
                logging.error(f"Simulation error: {e}")
                time.sleep(1)

        self.shutdown()
        logging.info("Simulation completed")

    def shutdown(self):
        self.running = False
        for worker in self.workers:
            worker.join(timeout=5)
        self.connection_pool.close_all()


CONFIG = {
    'ch_config': {
        'host': 'localhost',
        'user': 'default',
        'password': '',
        'database': 'course_db',
        'settings': {
            'max_execution_time': 30,
            'use_native_format': True  # Включаем Native формат
        }
    },
    'log_file': 'data/logs_data_3_000.csv',
    'target_table': 'logs_insert_test',
    'duration_minutes': 2,
    'min_batch_size': 100,
    'max_batch_size': 1000,
    'min_delay_sec': 0.1,
    'max_delay_sec': 5.0,
    'workers_count': 3,
    'max_queue_size': 10000
}

if __name__ == "__main__":
    simulator = LogSimulator(CONFIG)

    try:
        logging.info("Starting log simulation...")
        simulator.simulate_load()
    except KeyboardInterrupt:
        logging.info("Simulation interrupted by user")
    except Exception as e:
        logging.error(f"Fatal error: {e}")
    finally:
        simulator.shutdown()
        logging.info("Simulation stopped")