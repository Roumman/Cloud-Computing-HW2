# Задаёт зависимости между ресурсами, обеспечивая корректную последовательность развёртывания компонентов инфраструктуры.

# Например:
resource "null_resource" "setup_logbroker_1" {
  depends_on = [
    null_resource.setup_nat,
    null_resource.setup_clickhouse
  ]
}
