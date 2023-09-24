# Define a list of VM templates
variable "vm_templates" {
  default = ["ubuntutemplate20", "fedora-temp38"] # update this secton for specific OSs
}

# Define other potential variables like memory, disk size, etc., if they differ per VM.

resource "proxmox_vm_qemu" "vm_instance" {
  count       = length(var.vm_templates)
  name        = "terraform-vm${count.index + 1}"
  target_node = "pve"

  clone = element(var.vm_templates, count.index)

  os_type    = "cloud-init"
  cores      = 2
  sockets    = 1
  memory     = 4048 # You could also use the element() function if different VMs have different memory, etc.
  ciuser     = var.ciuser
  cipassword = var.cipassword
  disk {
    type    = "virtio"
    storage = "S1"
    size    = "20G"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=dhcp"
  sshkeys   = <<-EOF
  SSH_id_rsa.pub

  EOF
}