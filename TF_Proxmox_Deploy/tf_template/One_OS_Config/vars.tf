# secrets.tf

variable "pm_user" {
  description = "Proxmox username"
  type        = string
}

variable "pm_password" {
  description = "Proxmox password (or API token)"
  type        = string
  sensitive   = true
}

variable "ciuser" {
  type        = string
  description = "VM user name"
}

variable "cipassword" {
  type        = string
  description = "Password for creating new VM"
  sensitive   = true
}
