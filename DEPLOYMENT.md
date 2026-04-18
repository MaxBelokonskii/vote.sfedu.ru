# Руководство по развёртыванию vote.sfedu.ru

Инструкция для развёртывания приложения через **Portainer** на production-сервере.
Предполагается, что SSL-сертификат и HTTPS обслуживаются **внешним reverse-proxy**
заказчика (nginx/Traefik/другой), а Portainer управляет стеком Docker Compose.

---

## Содержание

1. [Требования к серверу](#1-требования-к-серверу)
2. [Подготовка сервера](#2-подготовка-сервера)
3. [Клонирование проекта и сборка образа](#3-клонирование-проекта-и-сборка-образа)
4. [Переменные окружения](#4-переменные-окружения)
5. [Интеграция с внешним reverse-proxy](#5-интеграция-с-внешним-reverse-proxy)
6. [Первый запуск стека в Portainer](#6-первый-запуск-стека-в-portainer)
7. [Создание первого администратора](#7-создание-первого-администратора)
8. [Проверка работоспособности](#8-проверка-работоспособности)
9. [Масштабирование](#9-масштабирование)
10. [Обновление приложения](#10-обновление-приложения)
11. [Резервное копирование](#11-резервное-копирование)
12. [Логи и мониторинг](#12-логи-и-мониторинг)
13. [Частые проблемы](#13-частые-проблемы)

---

## 1. Требования к серверу

| Параметр | Минимум | Рекомендуется |
|----------|---------|--------------|
| CPU | 2 vCPU | 4+ vCPU |
| RAM | 4 GB | 8+ GB |
| Диск | 40 GB SSD | 80+ GB SSD |
| ОС | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| Доступ | root или sudo | root или sudo |

**Сетевые требования:**
- Внешний reverse-proxy имеет сетевой доступ к порту приложения (по умолчанию `3000` на хосте, настраивается через `WEB_HOST_PORT`).
- Proxy обязан передавать заголовок `X-Forwarded-Proto: https` — иначе Rails не пометит session cookies как `Secure` и не добавит HSTS.
- Порты PostgreSQL (`5432`) и MinIO (`9000`, `9001`) наружу **не открываются** — сервисы общаются через внутреннюю Docker-сеть.

---

## 2. Подготовка сервера

### 2.1 Установить Docker и Docker Compose

```bash
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker
```

Docker Compose v2 входит в пакет `docker-ce` с 2023 года — отдельно ставить не нужно.

### 2.2 Установить Portainer (если ещё не установлен)

```bash
docker volume create portainer_data
docker run -d \
  --name portainer \
  --restart=always \
  -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest
```

Откройте `https://<server>:9443`, создайте администратора, выберите окружение **Local**.

### 2.3 Настроить файрвол

```bash
ufw allow 22/tcp
ufw allow 9443/tcp        # Portainer UI (ограничьте по IP при возможности)
ufw allow 3000/tcp        # web для reverse-proxy (или держите только внутри VPN)
ufw enable
```

---

## 3. Клонирование проекта и сборка образа

```bash
cd /opt
git clone https://github.com/MaxBelokonskii/vote.sfedu.ru.git vote
cd /opt/vote

# Собрать образ (3–7 минут)
docker build -t vote-app:latest .
```

> Можно собирать образ в CI и пушить в частный registry — тогда на сервере
> выполняется только `docker pull`. В этом случае задайте `DOCKER_IMAGE=<registry>/<tag>`
> в `.env` (по умолчанию используется локальный `vote-app:latest`).

---

## 4. Переменные окружения

Создайте файл `/opt/vote/.env` на основе `.env.example`:

```bash
cp .env.example .env
nano .env
```

Обязательно заполнить:

```env
SECRET_KEY_BASE=<сгенерировать: bin/rails secret>
APPLICATION_HOST=vote.sfedu.ru

POSTGRES_USER=vote
POSTGRES_PASSWORD=<надёжный пароль>
POSTGRES_DB=vote_production

S3_BUCKET=vote-uploads
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=<уникальный ключ>
S3_SECRET_ACCESS_KEY=<уникальный секрет>

AZURE_CLIENT_ID=<от ИТ-отдела ЮФУ>
AZURE_CLIENT_SECRET=<от ИТ-отдела ЮФУ>
AZURE_TENANT_ID=<от ИТ-отдела ЮФУ>

SFEDU_WSDL_PATH=<URL WSDL 1C>
SFEDU_WSDL_USERNAME=<логин>
SFEDU_WSDL_PASSWORD=<пароль>

# Отправка почты через Microsoft Graph (OAuth2 client_credentials)
# В Azure AD: application registration c application-permission Mail.Send + admin consent
GRAPH_TENANT_ID=<tenant-id>
GRAPH_CLIENT_ID=<client-id>
GRAPH_CLIENT_SECRET=<client-secret>
GRAPH_SENDER_EMAIL=noreply@sfedu.ru
```

Полезные опции:

```env
# Порт, на котором web-контейнер слушает на хосте (куда ходит reverse-proxy)
WEB_HOST_PORT=3000

# Если reverse-proxy НЕ передаёт X-Forwarded-Proto=https,
# выключите force_ssl и настройте HSTS на стороне proxy:
# RAILS_FORCE_SSL=false

# Готовый образ из registry (вместо локальной сборки)
# DOCKER_IMAGE=registry.example.com/vote-app:v1.2.3
```

> **Безопасность:** `.env` содержит секреты. Держите его вне git и ограничьте
> права доступа (`chmod 600 .env`).

---

## 5. Интеграция с внешним reverse-proxy

Web-контейнер публикует HTTP на `${WEB_HOST_PORT:-3000}`. Reverse-proxy заказчика
должен:

1. Терминировать TLS (сертификат на стороне proxy).
2. Проксировать запросы на `http://<docker-host>:3000`.
3. Передавать заголовки:
   ```
   X-Forwarded-Proto: https
   X-Forwarded-For:   <client-ip>
   X-Forwarded-Host:  vote.sfedu.ru
   Host:              vote.sfedu.ru
   ```
4. Поднять `proxy_read_timeout` до 60+ секунд (тяжёлые отчёты, экспорт Excel).
5. Разрешить WebSocket upgrade (если в будущем появятся ActionCable-каналы).

Пример location-блока для nginx на стороне proxy:

```nginx
location / {
    proxy_pass http://<docker-host>:3000;
    proxy_set_header Host              $host;
    proxy_set_header X-Real-IP         $remote_addr;
    proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
    proxy_read_timeout 60s;
}
```

---

## 6. Первый запуск стека в Portainer

### 6.1 Загрузить стек

Portainer → **Stacks** → **Add stack**:

- **Name:** `vote`
- **Build method:** `Upload` (залить `docker-compose.yml` из репозитория) либо `Repository` (указать git-репозиторий + путь до `docker-compose.yml`).
- **Environment variables:** нажать **Load variables from .env file** и загрузить `/opt/vote/.env`, либо скопировать значения руками в поле формы.
- Включить **Enable auto-update** (если используется git-репозиторий) — тогда Portainer будет перезапускать стек при новом коммите.

Нажмите **Deploy the stack**.

### 6.2 Порядок запуска

Compose-файл содержит healthchecks и `depends_on: condition: service_healthy/completed_successfully`,
поэтому контейнеры поднимаются в правильном порядке автоматически:

1. `db` (PostgreSQL) становится healthy.
2. `minio` становится healthy.
3. `minio-init` создаёт bucket и завершается (статус `exited (0)` — нормально).
4. `migrate` выполняет `rails db:migrate` и завершается (статус `exited (0)` — нормально).
5. `web` и `worker` стартуют и держатся в статусе `running`.

### 6.3 Data-миграции

`migrate` запускает только schema-миграции. Data-миграции (gem `data_migrate`)
выполните разово через Portainer → **Containers** → **+ Add container** или через консоль:

```bash
docker compose -f /opt/vote/docker-compose.yml --env-file /opt/vote/.env \
  run --rm migrate bundle exec rails db:migrate:data
```

### 6.4 Автозапуск стека после перезагрузки хоста

Сам Portainer поднимается с `--restart=always` (см. раздел 2.2). Контейнеры стека
имеют `restart: unless-stopped` в `docker-compose.yml`, поэтому Docker daemon сам
поднимет их после ребута сервера — никаких дополнительных действий не требуется.

Если нужна гарантированная проверка состояния стека при запуске хоста — включите
в Portainer **Stacks** → `vote` → **Editor** → **Force redeployment on update**.

---

## 7. Создание первого администратора

Через Portainer → **Containers** → выбрать запущенный `vote_web_1` → **Exec Console**,
либо из shell:

```bash
docker compose -f /opt/vote/docker-compose.yml --env-file /opt/vote/.env \
  exec web bundle exec rails runner "
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

---

## 8. Проверка работоспособности

```bash
# Health endpoint (напрямую, минуя proxy)
curl -I http://<docker-host>:3000/up

# Через внешний proxy
curl -I https://vote.sfedu.ru/up

# Заголовки безопасности (HSTS должен быть на ответе)
curl -sI https://vote.sfedu.ru | grep -E "Strict-Transport|X-Frame|X-Content"
```

В Portainer все сервисы в стеке `vote` должны быть в статусе **running** (кроме
`minio-init` и `migrate` — они one-shot и остаются в **exited (0)**).

---

## 9. Масштабирование

Portainer → **Stacks** → `vote` → **Editor**: добавить в секцию `web` (или `worker`):

```yaml
  web:
    ...
    deploy:
      replicas: 3
```

Нажать **Update the stack**. Для standalone Compose параметр `deploy.replicas`
работает, но всё реплики слушают один и тот же хост-порт — поэтому web
масштабируется либо через `docker compose up --scale web=N` (с удалением
`ports:` и проксированием только через внутренние upstream reverse-proxy), либо
вертикально (увеличение CPU/RAM).

Worker можно масштабировать без оговорок:

```bash
docker compose -f /opt/vote/docker-compose.yml --env-file /opt/vote/.env \
  up -d --scale worker=3 worker
```

---

## 10. Обновление приложения

### Вариант A — через git (если стек в Portainer подключён к репозиторию)

Portainer → **Stacks** → `vote` → **Pull and redeploy**. Portainer сам подтянет
свежий `docker-compose.yml` и перезапустит контейнеры. `migrate` выполнится
автоматически перед стартом нового `web`.

### Вариант B — локальная сборка

```bash
cd /opt/vote
git pull origin master
docker build -t vote-app:latest .
```

Затем Portainer → **Stacks** → `vote` → **Update the stack** → включить
**Re-pull image and redeploy** → **Update**.

Compose остановит старый `web`/`worker`, поднимет новые. `migrate` запустится
сам перед web.

### Откат

Откатитесь на предыдущий git-коммит, пересоберите образ с тегом
(`docker build -t vote-app:rollback .`), задайте `DOCKER_IMAGE=vote-app:rollback`
в стеке и нажмите **Update the stack**.

---

## 11. Резервное копирование

**Копии PostgreSQL не хранятся на том же сервере.** Бэкап формируется на stdout
и сразу отправляется на внешнее хранилище (S3-совместимое хранилище заказчика,
удалённый backup-сервер по SSH, облачный storage и т. д.).

### Ручной бэкап (dump → stdout)

```bash
# Дамп в файл на вашей рабочей машине
ssh <vote-server> "docker compose -f /opt/vote/docker-compose.yml --env-file /opt/vote/.env \
  exec -T db pg_dump -U \$POSTGRES_USER \$POSTGRES_DB" | gzip > vote_$(date +%F).sql.gz
```

### Автобэкап на внешнее S3 (пример)

Установите клиент внешнего S3 (`aws-cli`, `rclone` и т. п.), затем:

```bash
cat > /opt/vote/scripts/backup-to-s3.sh <<'EOF'
#!/bin/bash
set -euo pipefail
cd /opt/vote
source .env

DATE=$(date +%Y%m%d_%H%M%S)
REMOTE="s3://backup-bucket/vote/db_${DATE}.sql.gz"

docker compose --env-file .env exec -T db \
  pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" \
  | gzip \
  | aws s3 cp - "$REMOTE"

echo "Backup uploaded: $REMOTE"
EOF
chmod +x /opt/vote/scripts/backup-to-s3.sh

# Ежедневно в 02:00 (append, не перезаписываем crontab)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/vote/scripts/backup-to-s3.sh >> /var/log/vote-backup.log 2>&1") | crontab -
```

Файлы из MinIO (`minio_data` volume) также должны регулярно копироваться
на внешнее хранилище (`mc mirror` / `rclone sync`).

### Восстановление

```bash
# Остановить worker на время восстановления
docker compose -f /opt/vote/docker-compose.yml --env-file /opt/vote/.env stop worker

# Залить дамп
gunzip -c vote_YYYY-MM-DD.sql.gz \
  | docker compose -f /opt/vote/docker-compose.yml --env-file /opt/vote/.env \
      exec -T db psql -U $POSTGRES_USER $POSTGRES_DB

# Запустить worker обратно
docker compose -f /opt/vote/docker-compose.yml --env-file /opt/vote/.env start worker
```

---

## 12. Логи и мониторинг

Ошибки приложения пишутся в stdout контейнеров (TaggedLogging с request-id).
В Portainer логи доступны на странице каждого контейнера в реальном времени.

### CLI

```bash
# Логи всех сервисов стека
docker compose -f /opt/vote/docker-compose.yml logs -f

# Только web (последние 100 строк + follow)
docker compose -f /opt/vote/docker-compose.yml logs --tail 100 -f web

# Только worker
docker compose -f /opt/vote/docker-compose.yml logs --tail 100 -f worker

# Нагрузка всех контейнеров
docker stats
```

### Метрики Portainer

**Containers** → любой контейнер → **Stats** показывает CPU/RAM/IO в реальном
времени. Для долгоживущих метрик подключите Prometheus / Grafana или встроенный
Portainer Business (если используется).

---

## 13. Частые проблемы

### Контейнер в статусе `unhealthy` или циклически перезапускается

Portainer → контейнер → **Logs** (последние 50–100 строк). Чаще всего:
- Не заполнена обязательная переменная окружения → валидатор падает на старте.
- `db` ещё не готов — web/worker перезапустятся после того, как `db` станет healthy.

### 502 / 504 от reverse-proxy

- Проверьте, что proxy ходит на правильный host/port (`<docker-host>:${WEB_HOST_PORT}`).
- Увеличьте `proxy_read_timeout` на proxy (отчёты могут идти >30 секунд).

### Cookies не выставляются как Secure

Proxy не передаёт `X-Forwarded-Proto: https`. Либо настройте передачу заголовка,
либо выключите `RAILS_FORCE_SSL=false` и обеспечьте HSTS/редирект на стороне
proxy — но первый вариант предпочтителен.

### Письма не отправляются

```bash
docker compose -f /opt/vote/docker-compose.yml --env-file /opt/vote/.env \
  exec web bundle exec rails runner '
    Rails.logger.info ActionMailer::Base.delivery_method.inspect
  '
```

Должно вывести `:graph`. Затем проверьте, что в Azure AD у application
registration есть **application-permission** `Mail.Send` с **admin consent**
и что `GRAPH_SENDER_EMAIL` существует и лицензирован в тенанте.

### Полная остановка / удаление стека

Portainer → **Stacks** → `vote` → **Stop** (пауза) или **Delete** (удалить).
Volumes (`postgres_data`, `minio_data`) при удалении стека **не удаляются** —
данные сохранятся до ручного `docker volume rm`.

---

## Итоговый чеклист

- [ ] Docker + Portainer установлены, Portainer UI доступен.
- [ ] Внешний reverse-proxy настроен и передаёт `X-Forwarded-Proto: https`.
- [ ] `.env` заполнен, права `chmod 600`.
- [ ] Образ собран: `docker build -t vote-app:latest .` (или доступен из registry).
- [ ] Стек `vote` задеплоен в Portainer, все сервисы `running`, `migrate`/`minio-init` в `exited (0)`.
- [ ] Первый администратор создан.
- [ ] `curl https://vote.sfedu.ru/up` возвращает 200.
- [ ] Автобэкап настроен на внешнее хранилище.
- [ ] Внешнее хранилище файлов (MinIO) копируется регулярно.
