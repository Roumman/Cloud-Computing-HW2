# Создаёт VPC, публичные и приватные подсети, а также таблицу маршрутизации для трафика между подсетями.

resource "yandex_vpc_network" "hw2_network" {
  name = "hw2-network"
}

resource "yandex_vpc_subnet" "hw2_public_subnet" {
  # ... конфигурация публичной подсети
}

resource "yandex_vpc_route_table" "hw2_route_table" {
  # ... таблица маршрутизации
}

resource "yandex_vpc_subnet" "hw2_private_subnet" {
  # ... конфигурация приватной подсети
}
