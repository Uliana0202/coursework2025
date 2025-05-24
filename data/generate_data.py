import random
from datetime import datetime, timedelta
import csv

# Конфигурация генератора
NUM_RECORDS = 3000
START_DATE = datetime(2000, 1, 1)
END_DATE = datetime(2024, 12, 31)
CSV_FILE = 'logs_data_3_000.csv'


# Генерация данных
def generate_logins(num_logins=1000):
    domains = ['gmail.com', 'yahoo.com', 'outlook.com', 'company.org', 'domain.net']
    logins = []
    for i in range(1, num_logins + 1):
        user = f'user{i}'
        domain = random.choice(domains)
        logins.append(f'{user}@{domain}')
    return logins


def generate_events(num_events=100):
    event_types = ['login', 'logout', 'create', 'update', 'delete', 'read', 'search',
                   'export', 'import', 'backup', 'restore', 'error', 'warning', 'info',
                   'audit', 'auth', 'config_change', 'password_reset', 'session_start', 'session_end']

    # Генерация 100 уникальных событий
    events = []
    for i in range(num_events):
        if i < len(event_types):
            event = event_types[i]
        else:
            # Для оставшихся событий комбинируем базовые типы с суффиксами
            base_event = random.choice(event_types)
            suffix = random.choice(['_success', '_failed', '_attempt', '_complete', '_partial'])
            event = f"{base_event}{suffix}"
        events.append(event)
    return events


def generate_subsystems(num_subsystems=20):
    base_systems = ['auth', 'db', 'api', 'ui', 'storage', 'network',
                    'reporting', 'monitoring', 'billing', 'messaging']

    subsystems = []
    for i in range(num_subsystems):
        if i < len(base_systems):
            subsystem = base_systems[i]
        else:
            # Для оставшихся подсистем добавляем суффиксы
            base = random.choice(base_systems)
            suffix = random.choice(['_backend', '_frontend', '_v2', '_legacy', '_new'])
            subsystem = f"{base}{suffix}"
        subsystems.append(subsystem)
    return subsystems


def generate_comments():
    templates = [
        "User {login} performed {event} in {subsystem}",
        "Action {event} completed successfully in {subsystem}",
        "Failed to perform {event} in {subsystem} by {login}",
        "{event} operation was initiated by {login}",
        "System recorded {event} for subsystem {subsystem}",
        "Unexpected behavior during {event}",
        "Routine operation: {event}",
        "Security-related action: {event}",
        "Performance issue detected during {event}",
        "Debug information for {event}"
    ]
    return random.choice(templates)


def generate_descriptions(event):
    descriptions = {
        'login': "User authentication in the system",
        'logout': "User session termination",
        'create': "Creation of a new resource",
        'update': "Modification of an existing resource",
        'delete': "Removal of a resource",
        'error': "System or application error occurred",
        'warning': "Potential issue that needs attention",
        'info': "Informational message about system operation"
    }

    if event in descriptions:
        return descriptions[event]
    elif 'failed' in event:
        return f"Failed attempt to perform {event.replace('_failed', '')}"
    elif 'success' in event:
        return f"Successful completion of {event.replace('_success', '')}"
    else:
        return f"System event: {event}"


def random_timestamp(start, end):
    delta = end - start
    random_seconds = random.randint(0, int(delta.total_seconds()))
    return start + timedelta(seconds=random_seconds)


# Генерация данных
logins = generate_logins()
events = generate_events()
subsystems = generate_subsystems()

# Генерация CSV-файла
with open(CSV_FILE, 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)

    # Записываем заголовки
    writer.writerow(['timestamp', 'login', 'event', 'subsystem', 'comment', 'description'])

    for i in range(NUM_RECORDS):
        timestamp = random_timestamp(START_DATE, END_DATE)
        login = random.choice(logins)
        event = random.choice(events)
        subsystem = random.choice(subsystems)

        # Генерация комментария с подстановкой значений
        comment_template = generate_comments()
        comment = comment_template.format(login=login, event=event, subsystem=subsystem)

        description = generate_descriptions(event)

        # Записываем строку в CSV
        writer.writerow([
            timestamp.strftime('%Y-%m-%d %H:%M:%S'),
            login,
            event,
            subsystem,
            comment,
            description
        ])

    print(f"Generated a CSV file with {NUM_RECORDS} log entries")

print("Data generation completed")