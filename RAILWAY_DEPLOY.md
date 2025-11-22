# Railway Deployment Guide for Neo4j HTTPS

## Подготовка к деплою

Все необходимые файлы созданы:
- `Dockerfile` - образ с автоматической генерацией сертификатов
- `neo4j.conf` - конфигурация Neo4j с HTTPS
- `railway.json` - конфигурация Railway
- `generate-certificates-entrypoint.sh` - скрипт генерации сертификатов

## Способ 1: Через Railway Dashboard (Рекомендуется)

### Шаг 1: Создание нового сервиса

1. Откройте проект в Railway: https://railway.com/project/7c687313-0a78-4cee-872f-1d9a8e6d8653
2. Перейдите в окружение `test` (environmentId: 7d70c033-ba86-432d-8fba-e31b756be2ed)
3. Нажмите "New Service" → "GitHub Repo"
4. Выберите репозиторий с этим кодом
5. Укажите путь к сервису: `cases/assistant/neo4j-deploy`
6. Назовите сервис: `neo4j-https`

### Шаг 2: Настройка переменных окружения

В настройках сервиса `neo4j-https` добавьте:

```
NEO4J_AUTH=neo4j/your_strong_password_here
NEO4J_PLUGINS=["apoc"]
```

### Шаг 3: Настройка портов

Railway автоматически обнаружит порты из Dockerfile (7473, 7687).

### Шаг 4: Деплой

Railway автоматически:
- Соберет Docker образ
- Запустит контейнер
- Сгенерирует SSL сертификаты при первом запуске

## Способ 2: Через Railway CLI

### Шаг 1: Логин и привязка проекта

```bash
cd /home/dmitry/projects/texts/cases/assistant/neo4j-deploy

# Логин в Railway (требует интерактивной сессии)
railway login

# Привязка к проекту
railway link --project 7c687313-0a78-4cee-872f-1d9a8e6d8653

# Выбор окружения test
railway environment use test
```

### Шаг 2: Создание сервиса

```bash
# Создание нового сервиса neo4j-https
railway service create neo4j-https
```

### Шаг 3: Настройка переменных окружения

```bash
# Установка пароля Neo4j
railway variables set NEO4J_AUTH=neo4j/your_strong_password_here

# Установка плагинов
railway variables set NEO4J_PLUGINS='["apoc"]'
```

### Шаг 4: Деплой

```bash
# Деплой сервиса
railway up
```

## Проверка деплоя

### 1. Проверка статуса

```bash
railway status
railway logs
```

### 2. Получение URL

```bash
railway domain
```

### 3. Доступ к Neo4j Browser

Откройте в браузере: `https://your-service.up.railway.app:7473`

- Username: `neo4j`
- Password: (указанный в NEO4J_AUTH)

## Важные замечания

1. **Сертификаты**: Генерируются автоматически при первом запуске (самоподписанные)
2. **Пароль**: Обязательно измените пароль по умолчанию
3. **Порты**: Railway автоматически пробросит порты 7473 (HTTPS) и 7687 (Bolt)
4. **Данные**: Используйте Railway volumes для персистентности данных

## Troubleshooting

### Проблема: Сервис не запускается

```bash
# Проверьте логи
railway logs --service neo4j-https

# Проверьте переменные окружения
railway variables
```

### Проблема: Не могу подключиться

1. Проверьте, что порты правильно настроены
2. Убедитесь, что сервис запущен: `railway status`
3. Проверьте логи на ошибки SSL

### Проблема: Сертификаты не генерируются

Сертификаты генерируются автоматически при первом запуске. Если проблема:
1. Проверьте логи: `railway logs`
2. Убедитесь, что OpenSSL установлен в образе (уже включен в Dockerfile)

