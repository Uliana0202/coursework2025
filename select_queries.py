from clickhouse_driver import Client
from tabulate import tabulate
from time import sleep
import re

client = Client(
    host='localhost',
    user='default',
    password='',
    database='course_db'
)
#log_tables = ['logs_full_scan', 'logs_ordered', 'logs_with_indexes', 'logs_with_projections']
log_tables = ['logs_with_indexes_v2']
with open('queries_select/queries_rand.txt', 'r') as f:
    queries = [(line.strip(), f"query_{idx}") for idx, line in enumerate(f.readlines(), 1)]


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


def run_benchmark():
    for condition, query_name in queries:
        print(f"\n{'=' * 50}")
        print(f"Running benchmark for query type: {query_name}")
        print(f"Query condition: {condition}")
        print(f"{'=' * 50}\n")

        results = []
        test_queries = []

        for table in log_tables:
            query = f"SELECT count(*) FROM {table} WHERE {condition}"
            test_queries.append(query)
            print(f"Executing query on {table}:")
            print(query)

            try:
                count = execute_with_retry(query)
                if count:
                    print(f"Result count: {count[0][0]}\n")
                sleep(5)
            except Exception as e:
                print(f"Error executing query: {str(e)}\n")
                continue

        sleep(10)

        # Создаем точное условие для поиска выполненных запросов
        query_pattern = "|".join([re.escape(q) for q in test_queries])
        log_query = """
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
            WHERE type = 'QueryFinish'
              AND query_duration_ms > 0
              AND match(query, %(query_pattern)s)
            ORDER BY event_time DESC
            LIMIT %(limit)s
        """

        try:
            stats = execute_with_retry(log_query, {
                'query_pattern': query_pattern,
                'limit': len(log_tables)
            })

            if stats:
                for stat in stats:
                    tables_array = stat[0] if isinstance(stat[0], list) else [stat[0]]

                    insert_params = {
                        'tables': tables_array,
                        'query': stat[1],
                        'event_time': stat[2],
                        'query_duration_ms': stat[3],
                        'read_rows': stat[4],
                        'read_bytes': stat[5],
                        'memory_usage': stat[6],
                        'projections': stat[7],
                        'views': stat[8]
                    }

                    execute_with_retry("""
                        INSERT INTO test_query_log VALUES
                        (%(tables)s, %(query)s, %(event_time)s, %(query_duration_ms)s,
                        %(read_rows)s, %(read_bytes)s, %(memory_usage)s,
                        %(projections)s, %(views)s)
                        """, insert_params)

                    print("Successfully inserted query log data into test_select_query table\n")
                    results.append(list(stat))

        except Exception as e:
            print(f"Error getting query log: {str(e)}\n")
            continue

        if results:
            headers = [
                'Table', 'Query Text', 'Execution Time',
                'Duration (ms)', 'Rows Read', 'Bytes Read',
                'Memory Usage', 'Projections', 'Views'
            ]
            print(tabulate(results, headers=headers, tablefmt='grid', floatfmt=".2f"))
        else:
            print("No query log data found for this query type\n")

if __name__ == "__main__":
    run_benchmark()
