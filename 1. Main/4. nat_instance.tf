# Развёртывает NAT-инстанс для доступа приватных ВМ в интернет и настраивает IP forwarding с правилом MASQUERADE.

resource "yandex_compute_instance" "nat_instance" {
  # ... конфигурация NAT-инстанса
}

resource "null_resource" "setup_nat" {
  # ... провижининг NAT (IP forwarding + MASQUERADE)
}
