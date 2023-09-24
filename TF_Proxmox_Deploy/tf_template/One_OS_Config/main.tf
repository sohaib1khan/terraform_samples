# main.tf

resource "proxmox_vm_qemu" "vm_instance" {
  count       = 1
  name        = "terraform-vm${count.index + 1}"
  target_node = "pve"

  clone = "fedora-temp38" # Name of the VM/Template that you want to clone



  os_type    = "cloud-init"
  cores      = 2
  sockets    = 1
  memory     = 4048
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


  # Cloud Init Settings (Optional, but helpful for initialization)
  ipconfig0 = "ip=dhcp"
  sshkeys   = <<-EOF
  SSH_id_rsa.pub

  EOF
}
