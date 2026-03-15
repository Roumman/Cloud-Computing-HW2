# Определяет требуемую версию Terraform и провайдера Yandex Cloud для управления ресурсами.

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}
