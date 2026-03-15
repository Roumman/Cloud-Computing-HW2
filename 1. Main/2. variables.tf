# Объявляет переменные, необходимые для развёртывания инфраструктуры: ID облака, папки, зоны, SSH-ключи.

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "zone" {
  description = "Yandex Cloud zone"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for access to the VM (format: ssh-rsa AAAA...)"
  type        = string
  sensitive   = true
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key that matches ssh_public_key"
  type        = string
  default     = "~/.ssh/id_ed25519"
}
