# Neo4j HTTPS - Quick Start Guide

## Быстрый старт за 3 шага

### Шаг 1: Генерация SSL сертификатов

```bash
cd /cases/assistant/neo4j-deploy
chmod +x generate-certificates.sh
./generate-certificates.sh
```

### Шаг 2: Настройка пароля

Отредактируйте `docker-compose.yml` и измените пароль:

```yaml
environment:
  - NEO4J_AUTH=neo4j/your_strong_password_here
```

### Шаг 3: Запуск Neo4j

```bash
docker-compose up -d
```

### Доступ к Neo4j Browser

Откройте в браузере: **https://localhost:7473**

- **Username:** `neo4j`
- **Password:** (пароль, указанный в docker-compose.yml)

---

## Проверка работы

```bash
# Проверить статус
docker-compose ps

# Посмотреть логи
docker-compose logs -f neo4j

# Проверить подключение
curl -k https://localhost:7473
```

---

## Остановка

```bash
docker-compose down
```

Для полного удаления данных:

```bash
docker-compose down -v
```

---

## Решение проблем

### Браузер показывает предупреждение о сертификате

Это нормально для самоподписанных сертификатов. Нажмите "Дополнительно" → "Перейти на сайт".

### Neo4j не запускается

1. Проверьте логи: `docker-compose logs neo4j`
2. Убедитесь, что сертификаты созданы: `ls -la certificates/https/`
3. Проверьте, что порты свободны: `netstat -tlnp | grep -E '7473|7687'`

### Не могу подключиться

1. Проверьте, что контейнер запущен: `docker ps`
2. Проверьте порты: `docker-compose ps`
3. Попробуйте перезапустить: `docker-compose restart`

---

Для подробной документации см. [README.md](README.md)

