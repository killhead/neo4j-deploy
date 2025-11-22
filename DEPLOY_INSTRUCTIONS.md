# Инструкции по деплою Neo4j HTTPS в Railway

## ✅ Подготовка завершена

Все необходимые файлы созданы и готовы к деплою:
- ✅ `Dockerfile` - образ с автоматической генерацией SSL сертификатов
- ✅ `neo4j.conf` - конфигурация Neo4j с HTTPS
- ✅ `railway.json` - конфигурация Railway
- ✅ `generate-certificates-entrypoint.sh` - скрипт генерации сертификатов
- ✅ `.railwayignore` - исключения для Railway

## 🚀 Варианты деплоя

### Вариант 1: Через Railway Dashboard (Самый простой)

1. **Откройте проект в Railway:**
   - Перейдите: https://railway.com/project/7c687313-0a78-4cee-872f-1d9a8e6d8653
   - Выберите окружение **test** (environmentId: 7d70c033-ba86-432d-8fba-e31b756be2ed)

2. **Создайте новый сервис:**
   - Нажмите **"New Service"** → **"GitHub Repo"**
   - Выберите репозиторий с этим кодом
   - Укажите путь: `cases/assistant/neo4j-deploy`
   - Назовите сервис: **`neo4j-https`**

3. **Настройте переменные окружения:**
   ```
   NEO4J_AUTH=neo4j/your_strong_password_here
   NEO4J_PLUGINS=["apoc"]
   ```

4. **Railway автоматически:**
   - Обнаружит Dockerfile
   - Соберет образ
   - Запустит сервис
   - Сгенерирует SSL сертификаты при первом запуске

### Вариант 2: Через Railway CLI + MCP инструменты

#### Шаг 1: Логин в Railway CLI

```bash
cd /home/dmitry/projects/texts/cases/assistant/neo4j-deploy
railway login
```

Это откроет браузер для аутентификации.

#### Шаг 2: Привязка проекта

```bash
railway link --project 7c687313-0a78-4cee-872f-1d9a8e6d8653
```

#### Шаг 3: Выбор окружения

```bash
railway environment use 7d70c033-ba86-432d-8fba-e31b756be2ed
```

Или через MCP:
```bash
# После привязки проекта MCP инструменты будут работать
```

#### Шаг 4: Создание сервиса

Через CLI:
```bash
railway service create neo4j-https
```

Или через MCP (после привязки проекта):
- Используйте `mcp_Railway_deploy` с workspacePath

#### Шаг 5: Настройка переменных окружения

Через CLI:
```bash
railway variables set NEO4J_AUTH=neo4j/your_password --service neo4j-https
railway variables set 'NEO4J_PLUGINS=["apoc"]' --service neo4j-https
```

Или через MCP:
```bash
# Используйте mcp_Railway_set-variables
```

#### Шаг 6: Деплой

Через CLI:
```bash
railway up --service neo4j-https
```

Или через MCP:
```bash
# Используйте mcp_Railway_deploy с workspacePath
```

### Вариант 3: Использование готового скрипта

```bash
cd /home/dmitry/projects/texts/cases/assistant/neo4j-deploy
./deploy-to-railway.sh
```

Скрипт автоматически выполнит все шаги после логина.

## 📋 После деплоя

### Получение URL сервиса

```bash
railway domain --service neo4j-https
```

### Проверка статуса

```bash
railway status --service neo4j-https
railway logs --service neo4j-https
```

### Доступ к Neo4j Browser

Откройте в браузере: `https://your-service.up.railway.app:7473`

- **Username:** `neo4j`
- **Password:** (указанный в NEO4J_AUTH)

## ⚠️ Важные замечания

1. **Сертификаты:** Генерируются автоматически при первом запуске (самоподписанные)
2. **Пароль:** Обязательно измените пароль по умолчанию
3. **Порты:** Railway автоматически пробросит порты 7473 (HTTPS) и 7687 (Bolt)
4. **Данные:** Используйте Railway volumes для персистентности данных

## 🔧 Использование MCP инструментов после привязки

После выполнения `railway link`, вы можете использовать MCP инструменты:

```bash
# Деплой
mcp_Railway_deploy(workspacePath="/home/dmitry/projects/texts/cases/assistant/neo4j-deploy")

# Установка переменных
mcp_Railway_set-variables(
  workspacePath="/home/dmitry/projects/texts/cases/assistant/neo4j-deploy",
  variables=["NEO4J_AUTH=neo4j/password", "NEO4J_PLUGINS=[\"apoc\"]"]
)

# Просмотр логов
mcp_Railway_get-logs(workspacePath="...", logType="deploy")

# Генерация домена
mcp_Railway_generate-domain(workspacePath="...")
```

## 📚 Дополнительная информация

- [Railway Documentation](https://docs.railway.app)
- [Neo4j Documentation](https://neo4j.com/docs/)
- Подробная документация: см. `README.md` и `RAILWAY_DEPLOY.md`

