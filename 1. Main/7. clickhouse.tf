# Развёртывает ВМ с ClickHouse в приватной подсети и настраивает её для хранения структурированных логов.

resource "yandex_compute_instance" "clickhouse" {
  # ... конфигурация ВМ ClickHouse
}

resource "null_resource" "setup_clickhouse" {
  # ... провижининг ClickHouse
}
