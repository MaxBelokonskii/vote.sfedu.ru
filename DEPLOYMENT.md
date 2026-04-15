# Руководство по развёртыванию vote.sfedu.ru

Пошаговая инструкция для развёртывания приложения на production-сервере под ключ.  
После выполнения последнего шага приложение будет доступно по адресу `https://vote.sfedu.ru`.

---

## Содержание

1. [Требования к серверу](#1-требования-к-серверу)
2. [Подготовка сервера](#2-подготовка-сервера)
3. [SSL-сертификаты](#3-ssl-сертификаты) ⚠️ **Требует решения**
4. [DNS](#4-dns)
5. [Клонирование проекта](#5-клонирование-проекта)
6. [Переменные окружения](#6-переменные-окружения)
7. [Первый запуск](#7-первый-запуск)
8. [Проверка работоспособности](#8-проверка-работоспособности)
9. [Горизонтальное масштабирование](#9-горизонтальное-масштабирование)
10. [Автоматическое масштабирование](#10-автоматическое-масштабирование)
11. [Обновление приложения (rolling deploy)](#11-обновление-приложения-rolling-deploy)
12. [Резервное копирование](#12-резервное-копирование)
13. [Логи и мониторинг](#13-логи-и-мониторинг)
14. [Частые проблемы](#14-частые-проблемы)

---

## 1. Требования к серверу

| Параметр | Минимум | Рекомендуется |
|----------|---------|--------------|
| CPU | 2 vCPU | 4+ vCPU |
| RAM | 4 GB | 8+ GB |
| Диск | 40 GB SSD | 80+ GB SSD |
| ОС | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| Доступ | root или sudo | root или sudo |

**Открытые порты:** 22 (SSH), 80 (HTTP), 443 (HTTPS).  
Все остальные порты (5432, 9000, 9001, 3000) должны быть закрыты файрволом — сервисы общаются через внутреннюю Docker-сеть.

---

## 2. Подготовка сервера

### 2.1 Обновить систему

```bash
apt-get update && apt-get upgrade -y
```

### 2.2 Установить Docker

```bash
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker
```

### 2.3 Инициализировать Docker Swarm

```bash
docker swarm init
```

> Если у сервера несколько IP-адресов, укажите публичный:
> ```bash
> docker swarm init --advertise-addr <PUBLIC_IP>
> ```

### 2.4 Настроить файрвол

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

### 2.5 Установить вспомогательные утилиты

```bash
apt-get install -y bc curl git
```

---

## 3. SSL-сертификаты

> ⚠️ **Этот вопрос требует решения перед развёртыванием.**
>
> Без SSL-сертификата приложение не будет работать по HTTPS.

Приложение ожидает сертификат в Docker volume `nginx_ssl` по путям:
- `/etc/nginx/ssl/fullchain.pem`
- `/etc/nginx/ssl/privkey.pem`

### Вариант A: Let's Encrypt (certbot) — бесплатно, рекомендуется

Предварительно: домен `vote.sfedu.ru` должен указывать на этот сервер (см. раздел 4).

```bash
# Установить certbot
apt-get install -y certbot

# Получить сертификат (порт 80 должен быть открыт)
certbot certonly --standalone -d vote.sfedu.ru

# Создать volume и скопировать сертификаты
docker volume create nginx_ssl
VOLUME_PATH=$(docker volume inspect nginx_ssl --format '{{.Mountpoint}}')

cp /etc/letsencrypt/live/vote.sfedu.ru/fullchain.pem $VOLUME_PATH/
cp /etc/letsencrypt/live/vote.sfedu.ru/privkey.pem  $VOLUME_PATH/

# Автообновление сертификата (Let's Encrypt выдаёт на 90 дней)
# Используем (crontab -l; echo "...") | crontab - чтобы ДОБАВИТЬ задачу,
# а не перезаписать весь crontab.
(crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet && \
  cp /etc/letsencrypt/live/vote.sfedu.ru/fullchain.pem $VOLUME_PATH/ && \
  cp /etc/letsencrypt/live/vote.sfedu.ru/privkey.pem $VOLUME_PATH/ && \
  docker service update --force vote_nginx") | crontab -
```

### Вариант B: Свой сертификат

```bash
docker volume create nginx_ssl
VOLUME_PATH=$(docker volume inspect nginx_ssl --format '{{.Mountpoint}}')

# Скопировать ваши файлы:
cp /path/to/your/fullchain.pem $VOLUME_PATH/
cp /path/to/your/privkey.pem   $VOLUME_PATH/
```

### Вариант C: Cloudflare (проксирование)

Если используете Cloudflare как прокси — SSL-терминация происходит на уровне Cloudflare.  
В этом случае между Cloudflare и вашим сервером можно использовать self-signed сертификат
(origin certificate от Cloudflare) или HTTP (только при включённом Full режиме в Cloudflare).

---

## 4. DNS

Добавьте A-запись для домена:

```
vote.sfedu.ru.   A   <PUBLIC_IP_ADDRESS>
```

Проверить распространение DNS:

```bash
dig vote.sfedu.ru +short
# Должен вернуть IP вашего сервера
```

---

## 5. Клонирование проекта

```bash
cd /opt
git clone https://github.com/MaxBelokonskii/vote.sfedu.ru.git vote
cd /opt/vote
```

---

## 6. Переменные окружения

Создайте файл `.env.production` в корне проекта:

```bash
cp .env.example .env.production
nano .env.production  # или vim, или другой редактор
```

Обязательно заполнить все значения:

```env
# ===== ОБЯЗАТЕЛЬНО =====

# Генерируется командой: bin/rails secret
SECRET_KEY_BASE=<сгенерируйте_новый_ключ>

APPLICATION_HOST=vote.sfedu.ru

# PostgreSQL
POSTGRES_USER=vote
POSTGRES_PASSWORD=<придумайте_надёжный_пароль>
POSTGRES_DB=vote_production

# S3 / MinIO — задайте уникальные учётные данные
S3_BUCKET=vote-uploads
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=<придумайте_уникальный_ключ>
S3_SECRET_ACCESS_KEY=<придумайте_уникальный_секрет>

# Azure AD OAuth (для входа через Microsoft ЮФУ)
AZURE_CLIENT_ID=<получить_от_ИТ_отдела_ЮФУ>
AZURE_CLIENT_SECRET=<получить_от_ИТ_отдела_ЮФУ>
AZURE_TENANT_ID=<получить_от_ИТ_отдела_ЮФУ>

# SOAP / 1C API
SFEDU_WSDL_PATH=<URL_WSDL_от_1C>
SFEDU_WSDL_USERNAME=<логин>
SFEDU_WSDL_PASSWORD=<пароль>

# SMTP (для почтовых уведомлений)
SMTP_ADDRESS=smtp.sfedu.ru
SMTP_DOMAIN=sfedu.ru
SMTP_USERNAME=<логин>
SMTP_PASSWORD=<пароль>
SMTP_PORT=587

# ===== ОПЦИОНАЛЬНО =====

# ASSET_HOST=vote.sfedu.ru
# DB_POOL=5
# WEB_CONCURRENCY=2
# MAX_THREADS=2
# JOB_CONCURRENCY=2

# ВАЖНО: никогда не устанавливать в production!
# DEBUG_LOGIN_INTO_ACCOUNT=  (оставить пустым или не добавлять вообще)
```

> **Безопасность:** файл `.env.production` содержит секреты — не добавляйте его в git.  
> Убедитесь, что он указан в `.gitignore`.

---

## 7. Первый запуск

### 7.1 Собрать Docker-образ

```bash
cd /opt/vote

# Собрать образ (занимает 3–7 минут)
docker build -t vote-app:latest .
```

### 7.2 Создать volume для SSL (если не создан в шаге 3)

```bash
docker volume create nginx_ssl
```

### 7.3 Инициализировать базу данных

```bash
# Запустить только PostgreSQL
docker stack deploy -c docker-stack.yml vote

# Подождать, пока PostgreSQL станет healthy (10–20 секунд)
watch docker service ls

# Запустить миграции
docker run --rm \
  --network vote_internal \
  --env-file .env.production \
  -e DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}" \
  -e RAILS_ENV=production \
  vote-app:latest \
  bundle exec rails db:create db:migrate

# Запустить data-миграции (data_migrate gem, документировано в CLAUDE.md)
source .env.production && docker run --rm \
  --network vote_internal \
  --env-file .env.production \
  -e DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}" \
  -e RAILS_ENV=production \
  vote-app:latest \
  bundle exec rails db:migrate:data

# Создать первого администратора
docker run --rm -it \
  --network vote_internal \
  --env-file .env.production \
  -e DATABASE_URL="postgres://${POSTGRES_USER}:${POSTGRES_PASSWORD}@db:5432/${POSTGRES_DB}" \
  -e RAILS_ENV=production \
  vote-app:latest \
  bundle exec rails runner "
    teacher = Teacher.create!(name: 'Администратор', external_id: 'admin-001')
    user = User.new(
      email: 'admin@sfedu.ru',
      nickname: 'admin',
      identity_url: 'https://openid.sfedu.ru/server.php/idpage?user=admin',
      role: :admin,
      kind: teacher
    )
    user.save!(validate: false)
    puts \"Admin created: #{user.email}\"
  "
```

### 7.4 Запустить весь стек

```bash
docker stack deploy -c docker-stack.yml vote

# Наблюдать за запуском (все сервисы должны перейти в Ready/Running)
watch docker service ls
```

Дождаться, пока все сервисы покажут `1/1` или `2/2`:

```
ID       NAME             MODE         REPLICAS   IMAGE
xxx      vote_db          replicated   1/1        postgres:16-alpine
xxx      vote_minio       replicated   1/1        minio/minio
xxx      vote_nginx       replicated   1/1        nginx:1.25-alpine
xxx      vote_web         replicated   2/2        vote-app:latest
xxx      vote_worker      replicated   1/1        vote-app:latest
```

---

## 8. Проверка работоспособности

```bash
# 1. Health check endpoint (должен вернуть 200)
curl -k https://vote.sfedu.ru/up

# 2. Главная страница
curl -I https://vote.sfedu.ru

# 3. Проверить HTTPS редирект
curl -I http://vote.sfedu.ru
# Должен вернуть: HTTP/1.1 301 Moved Permanently

# 4. Проверить заголовки безопасности
curl -sI https://vote.sfedu.ru | grep -E "Strict-Transport|X-Frame|X-Content"

# 5. Логи web-сервиса
docker service logs vote_web --tail 50 -f

# 6. Логи nginx
docker service logs vote_nginx --tail 20
```

---

## 9. Горизонтальное масштабирование

Ручное управление количеством web-реплик:

```bash
# Увеличить до 4 реплик
docker service scale vote_web=4

# Уменьшить до 2 реплик
docker service scale vote_web=2

# Текущее состояние
docker service ls
docker service ps vote_web
```

---

## 10. Автоматическое масштабирование

Скрипт `scripts/autoscale.sh` следит за средней загрузкой CPU web-реплик и автоматически
увеличивает или уменьшает их количество.

### Настройка через cron (запускать каждую минуту)

```bash
# Проверить работу скрипта вручную
AUTOSCALE_SERVICE=vote_web bash /opt/vote/scripts/autoscale.sh

# Добавить в cron
crontab -e
```

Добавить строку:

```cron
* * * * * AUTOSCALE_SERVICE=vote_web MIN_REPLICAS=2 MAX_REPLICAS=8 SCALE_UP_THRESHOLD=70 SCALE_DOWN_THRESHOLD=20 bash /opt/vote/scripts/autoscale.sh >> /var/log/vote-autoscale.log 2>&1
```

### Параметры автоскейлера

| Переменная | По умолчанию | Описание |
|-----------|-------------|---------|
| `AUTOSCALE_SERVICE` | `vote_web` | Имя сервиса Swarm |
| `MIN_REPLICAS` | `2` | Минимальное кол-во реплик |
| `MAX_REPLICAS` | `8` | Максимальное кол-во реплик |
| `SCALE_UP_THRESHOLD` | `70` | CPU (%) для увеличения реплик |
| `SCALE_DOWN_THRESHOLD` | `20` | CPU (%) для уменьшения реплик |
| `COOLDOWN_SECONDS` | `120` | Пауза между операциями масштабирования |

---

## 11. Обновление приложения (rolling deploy)

```bash
cd /opt/vote

# 1. Получить свежий код
git pull origin master

# 2. Пересобрать образ с новым тегом
IMAGE_TAG=$(git rev-parse --short HEAD)
docker build -t "vote-app:${IMAGE_TAG}" .

# 3. Запустить rolling deploy (автоматически выполняет миграции)
IMAGE_TAG=$IMAGE_TAG bash scripts/deploy.sh
```

Rolling deploy обновляет реплики **по одной** (`start-first`):
1. Запускает новую реплику
2. Ждёт её health check
3. Останавливает старую реплику
4. Переходит к следующей

При ошибке происходит автоматический откат (`rollback`).

---

## 12. Резервное копирование

### Автоматический бэкап PostgreSQL

```bash
# Создать скрипт бэкапа
cat > /opt/vote/scripts/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR=/var/backups/vote
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Дамп базы данных
docker run --rm \
  --network vote_internal \
  -e PGPASSWORD=${POSTGRES_PASSWORD} \
  postgres:16-alpine \
  pg_dump -h db -U ${POSTGRES_USER} ${POSTGRES_DB} \
  | gzip > "${BACKUP_DIR}/db_${DATE}.sql.gz"

# Удалить бэкапы старше 30 дней
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete

echo "Backup created: ${BACKUP_DIR}/db_${DATE}.sql.gz"
EOF
chmod +x /opt/vote/scripts/backup.sh

# Добавить в cron (ежедневно в 2:00) — append, не перезаписать crontab
(crontab -l 2>/dev/null; echo "0 2 * * * source /opt/vote/.env.production && bash /opt/vote/scripts/backup.sh") | crontab -
```

### Восстановление из бэкапа

```bash
# Остановить воркер (не записывает в БД во время восстановления)
docker service scale vote_worker=0

# Восстановить
gunzip -c /var/backups/vote/db_YYYYMMDD_HHMMSS.sql.gz | \
  docker run --rm -i \
    --network vote_internal \
    -e PGPASSWORD=${POSTGRES_PASSWORD} \
    postgres:16-alpine \
    psql -h db -U ${POSTGRES_USER} ${POSTGRES_DB}

# Запустить воркер обратно
docker service scale vote_worker=1
```

---

## 13. Логи и мониторинг

> ⚠️ **Централизованный мониторинг ошибок находится в разработке** (Sentry отключён,
> замена запланирована в отдельной задаче).

### Просмотр логов

```bash
# Все логи web-сервиса (последние 100 строк + follow)
docker service logs vote_web --tail 100 -f

# Логи nginx
docker service logs vote_nginx --tail 50 -f

# Логи воркера (Solid Queue)
docker service logs vote_worker --tail 50 -f

# Состояние всех сервисов
docker service ls
docker service ps vote_web
```

### Мониторинг нагрузки

```bash
# CPU/память всех контейнеров в реальном времени
docker stats

# Только web-контейнеры
docker stats $(docker ps --filter name=vote_web --format "{{.Names}}")

# Лог автоскейлера
tail -f /var/log/vote-autoscale.log
```

---

## 14. Частые проблемы

### Сервис не запускается

```bash
# Посмотреть детали
docker service ps vote_web --no-trunc
docker service logs vote_web --tail 30
```

### База данных недоступна

```bash
# Проверить статус PostgreSQL
docker service ls | grep vote_db
docker service logs vote_db --tail 20
```

### Ошибки SSL

```bash
# Проверить сертификат
VOLUME_PATH=$(docker volume inspect nginx_ssl --format '{{.Mountpoint}}')
openssl x509 -in $VOLUME_PATH/fullchain.pem -noout -dates
```

### Ручной откат к предыдущей версии

```bash
docker service rollback vote_web
docker service rollback vote_worker
```

### Полная остановка стека

```bash
docker stack rm vote
```

---

## Итоговый чеклист

- [ ] Сервер настроен (Docker, Swarm, файрвол)
- [ ] DNS направлен на сервер
- [ ] SSL-сертификат получен и размещён в `nginx_ssl` volume
- [ ] `.env.production` заполнен всеми значениями
- [ ] Образ собран: `docker build -t vote-app:latest .`
- [ ] База создана и мигрирована: `rails db:create db:migrate && rails db:migrate:data`
- [ ] Первый администратор создан
- [ ] Стек запущен: `docker stack deploy -c docker-stack.yml vote`
- [ ] Все сервисы в статусе Running
- [ ] Приложение отвечает на `https://vote.sfedu.ru`
- [ ] Автоскейлер настроен в cron
- [ ] Автобэкап настроен в cron
