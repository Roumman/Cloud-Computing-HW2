# Развёртывает ВМ с NGINX в публичной подсети и настраивает её как балансировщик нагрузки для backend-серверов.

resource "yandex_compute_instance" "nginx" {
  # ... конфигурация ВМ NGINX
}

resource "null_resource" "setup_nginx" {
  # ... провижининг NGINX
}
