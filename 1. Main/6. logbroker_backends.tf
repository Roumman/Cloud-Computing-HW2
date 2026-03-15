# Развёртывает две ВМ с сервисом Logbroker в приватной подсети и настраивает их для приёма и обработки логов.

resource "yandex_compute_instance" "logbroker_1" {
  # ... конфигурация logbroker-1
}

resource "yandex_compute_instance" "logbroker_2" {
  # ... конфигурация logbroker-2
}

resource "null_resource" "setup_logbroker_1" {
  # ... провижининг logbroker-1
}

resource "null_resource" "setup_logbroker_2" {
  # ... провижининг logbroker-2
}
