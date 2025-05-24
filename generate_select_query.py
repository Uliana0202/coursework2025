from itertools import combinations
import random


attributes = {
    'timestamp': "timestamp <= '2012-11-21'",
    'login': "login LIKE 'user10%'",
    'event': "event LIKE 'session%'",
    'subsystem': "subsystem LIKE 'b%'"
}


def generate_queries():
    queries = []

    for r in range(1, len(attributes) + 1):
        for combo in combinations(attributes.keys(), r):
            conditions = []
            for attr in combo:
                conditions.append(attributes[attr])

                if len(conditions) == 1:
                    where_clause = conditions[0]
                else:
                    # Случайно выбираем операторы между условиями
                    operators = [random.choice(['AND', 'OR']) for _ in range(len(conditions) - 1)]

                    # Чередуем условия и операторы
                    where_parts = []
                    for i in range(len(conditions)):
                        where_parts.append(conditions[i])
                        if i < len(operators):
                            where_parts.append(operators[i])
                    where_clause = " ".join(where_parts)

            query = {
                'attributes': combo,
                'where': where_clause,
                'description': f"Query by {', '.join(combo)} "
            }
            queries.append(query)

            with open('queries.txt', 'w') as f:
                for q in queries:
                    f.write(f"{q['where']}\n")
    return queries

queries = generate_queries()
for i, q in enumerate(queries, 1):
    print(f"\nQuery #{i}: {q['description']}")
    print(f"SELECT count(*) FROM table_name WHERE {q['where']};")