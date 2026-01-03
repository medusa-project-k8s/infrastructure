# Proxmox Provider Configuration
variable "pm_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "pm_user" {
  description = "Proxmox username (e.g. root@pam)"
  type        = string
  sensitive   = true
}

variable "pm_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Skip TLS verification for Proxmox API"
  type        = bool
  default     = true
}

# VM Configuration
variable "vms" {
  description = "Map of VMs to create with their configurations"
  type = map(object({
    node_name      = string
    iso_file       = optional(string, null)      # Use null when using template_id
    template_id    = optional(string, null)      # VM ID of template to clone from (e.g., "100")
    cores          = number
    memory         = number
    disk_size      = number
    disk_type      = string
    disk_storage   = string
    network_model  = string
    network_bridge = string
    # Cloud-init configuration (recommended when using templates)
    username       = optional(string, "ubuntu")
    password       = optional(string, null)      # Set password or use ssh_keys (more secure)
    ssh_keys       = optional(list(string), [])  # List of SSH public keys
    ip_address     = optional(string, null)      # Optional: "192.168.1.100/24" for static IP
    ip_gateway     = optional(string, null)      # Optional: "192.168.1.1"
    nameserver     = optional(string, "8.8.8.8")
  }))
  default = {
    "talos-linux-vm" = {
      node_name      = "pve"
      iso_file       = "local:iso/talos-amd64.iso"
      cores          = 2
      memory         = 2048
      disk_size      = 32
      disk_type      = "scsi0"
      disk_storage   = "local-lvm"
      network_model  = "virtio"
      network_bridge = "vmbr0"
    }
  }
}

