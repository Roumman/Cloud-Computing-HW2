# Скрипт автоматизирует установку и настройку сервиса Logbroker на виртуальной машине: устанавливает зависимости Python, настраивает виртуальное окружение, создаёт директорию для буфера логов, развёртывает и запускает сервис как systemd‑юнит с привязкой к порту 80.

# !/bin/bash

set -e

CLICKHOUSE_HOST="${CLICKHOUSE_HOST:-10.2.0.24}"
CLICKHOUSE_USER="${CLICKHOUSE_USER:-logbroker}"
CLICKHOUSE_PASSWORD="${CLICKHOUSE_PASSWORD:-logbroker}"
LOGBROKER_DIR="${1:-$HOME/logbroker}"


if [ ! -d "$LOGBROKER_DIR" ]; then
  echo "Папка $LOGBROKER_DIR не найдена. Скопируйте logbroker на ВМ и укажите путь."
  exit 1
fi

echo "==> Установка Python3 и venv..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv

echo "==> Создание виртуального окружения и установка зависимостей..."
cd "$LOGBROKER_DIR"
python3 -m venv venv
./venv/bin/pip install -r requirements.txt

echo "==> Директория для буфера..."
sudo mkdir -p /var/lib/logbroker
sudo chown "$USER:$USER" /var/lib/logbroker

echo "==> Установка systemd unit и запуск сервиса..."
sudo tee /etc/systemd/system/logbroker.service > /dev/null << EOF
[Unit]
Description=Logbroker service
After=network.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=$LOGBROKER_DIR
Environment="CLICKHOUSE_HOST=$CLICKHOUSE_HOST"
Environment="CLICKHOUSE_PORT=8123"
Environment="CLICKHOUSE_USER=$CLICKHOUSE_USER"
Environment="CLICKHOUSE_PASSWORD=$CLICKHOUSE_PASSWORD"
Environment="BUFFER_PATH=/var/lib/logbroker/buffer.log"
ExecStart=$LOGBROKER_DIR/venv/bin/uvicorn main:app --host 0.0.0.0 --port 80
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

PYTHON_BIN="$LOGBROKER_DIR/venv/bin/python3"
if [ -f "$PYTHON_BIN" ]; then
  sudo setcap 'cap_net_bind_service=+ep' "$(readlink -f "$PYTHON_BIN")" 2>/dev/null || true
fi

sudo systemctl daemon-reload
sudo systemctl enable logbroker
sudo systemctl start logbroker

echo "==> Готово. Logbroker запущен как сервис (порт 80)."
echo "Проверка: curl http://localhost/health"
echo "Логи: sudo journalctl -u logbroker -f"
