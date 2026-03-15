# Определяет выходные параметры развёрнутой инфраструктуры — публичные и приватные IP-адреса сервисов.

output "nginx_public_ip" {
  description = "Public IP address of nginx"
  value       = yandex_compute_instance.nginx.network_interface.nat_ip_address
}

output "nat_instance_public_ip" {
  # ... остальные outputs
}
