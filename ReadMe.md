# Cloud Logbroker: инструкция по развёртыванию
## Цель: развернуть logbroker‑сервис в Yandex Cloud с использованием Terraform (VPC, NAT, 2 backend‑ВМ с logbroker, ClickHouse, nginx).

## Предварительные требования
+ Установлены: `yc`, `terraform` (или `OpenTofu` с совместимым CLI), `ssh`, `scp`;
+ Создан сервисный аккаунт в YC с правами на создание ВМ и сеть;
+ Получены: `cloud_id`, `folder_id`, зона (например, `ru-central1-b`);
+ Сгенерирован SSH‑ключ (`ssh-ed25519` или `rsa`);
+ Экспортирован токен для YC:
``` bash
export YC_TOKEN=$(yc iam create-token --impersonate-service-account-id<service_account_ID>)
```
## 1. Настройка Terraform
1) Заполните terraform.tfvars:
``` bash
cloud_id       = "b1g..."
folder_id      = "b1g..."
zone           = "ru-central1-b"
ssh_public_key = "ssh-ed25519 AAAA... your-key-comment"
```
2) Выполните команды:
``` bash
terraform init
terraform plan
terraform apply
```

3) После `apply` выполните terraform `output` — будут выведены:
``` bash
nginx_public_ip — публичный IP nginx;
nat_instance_public_ip — публичный IP NAT/jump‑host;
logbroker_private_ips — приватные IP двух backend‑ВМ;
clickhouse_private_ip — приватный IP ClickHouse.
```

## 2. Что делает terraform apply
+ Создаёт VPC, сеть (публичная и приватная подсети, таблица маршрутизации).
+ Настраивает NAT‑инстанс (IP‑forwarding, `iptables`- правило `MASQUERADE`).
+ Развёртывает ClickHouse (Docker, контейнер `clickhouse/clickhouse-server`, база/таблица `default.logs`, пользователь `logbroker`).
+ Развёртывает 2 backend‑ВМ с logbroker (копирует каталог `logbroker/`, устанавливает Python, создаёт `venv`, развёртывает `systemd` ‑сервис на порту `80`).
+ Развёртывает `nginx‑ВМ` (устанавливает nginx, создаёт конфиг `logbroker.conf`, включает маршруты `/nginx_health` и проксирование запросов на logbroker).

## 3. Проверка инфраструктуры
1) Выполните `terraform output` для получения IP‑адресов.
2) Проверьте nginx:
``` bash
curl http://$(terraform output -raw nginx_public_ip)/nginx_health
curl http://$(terraform output -raw nginx_public_ip)/health
```
3) Проверьте ClickHouse:
- Подключитесь по SSH:
ssh -J ubuntu@$(terraform output -raw nat_instance_public_ip) ubuntu@$(terraform output -raw clickhouse_private_ip)
- Выполните:
  + curl http://localhost:8123/ping
  + sudo docker exec -it clickhouse-server clickhouse-client -q "SHOW TABLES FROM default"
(должна быть таблица logs).

## 4. End‑to‑end проверка логов
1) Отправьте логи с локальной машины:
``` bash
curl -X POST "http://$(terraform output -raw nginx_public_ip)/write_log" -d $'first log via nginx\nsecond log via nginx'
```
2) Проверьте логи в ClickHouse:
- Подключитесь по SSH (см. пункт 3).
  Выполните:
  + sudo docker exec -it clickhouse-server clickhouse-client -q "SELECT count(), any(message) FROM default.logs"
  + Ожидаемый результат: count() > 0, в сообщении видна одна из отправленных строк.

## 5. Гарантия доставки логов
Logbroker:

- принимает запрос /write_log;
- пишет строки логов в файл (/var/lib/logbroker/buffer.log) и выполняет fsync;
- отвечает 200 OK только после записи в буфер;
- раз в секунду читает буфер и отправляет данные в ClickHouse через HTTP API;
- при успешной вставке очищает файл буфера;
- при остановке сервиса выполняет финальный flush.
