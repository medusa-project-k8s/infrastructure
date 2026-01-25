terraform {
    required_providers {
        proxmox = {
            source  = "bpg/proxmox"
            version = "~> 0.50"
        }
    }
}

provider "proxmox" {
    endpoint  = var.pm_api_url
    username  = var.pm_user
    password  = var.pm_password
    insecure  = var.pm_tls_insecure
}

resource "proxmox_virtual_environment_vm" "vms" {
    for_each = var.vms
    stop_on_destroy = false

    name      = each.key
    node_name = each.value.node_name

    # For ISO-based installs (Talos), boot from disk first after install.
    boot_order = each.value.template_id == null && each.value.iso_file != null ? [each.value.disk_type, "net0", "ide3"] : [each.value.disk_type, "net0"]

    # Clone from template if template_id is provided, otherwise boot from ISO
    dynamic "clone" {
        for_each = each.value.template_id != null ? [1] : []
        content {
            vm_id = each.value.template_id
        }
    }

    # Boot from ISO (only if template_id is not provided)
    dynamic "cdrom" {
        for_each = each.value.template_id == null && each.value.iso_file != null ? [1] : []
        content {
            file_id = each.value.iso_file
        }
    }

    cpu {
        cores = each.value.cores
        type  = "host"
    }

    memory {
        dedicated = each.value.memory
    }

    disk {
        datastore_id = each.value.disk_storage
        file_format  = "raw"
        interface    = each.value.disk_type
        size         = each.value.disk_size
        discard      = "on"
    }

    network_device {
        model  = each.value.network_model
        bridge = each.value.network_bridge
    }

    # Cloud-init initialization (works with templates)
    dynamic "initialization" {
        for_each = each.value.template_id != null ? [1] : []
        content {
            datastore_id = each.value.disk_storage
            
            user_account {
                username = each.value.username
                password = each.value.password
                keys     = length(each.value.ssh_keys) > 0 ? each.value.ssh_keys : null
            }

            dynamic "ip_config" {
                for_each = each.value.ip_address != null ? [1] : []
                content {
                    ipv4 {
                        address = each.value.ip_address
                        gateway = each.value.ip_gateway
                    }
                }
            }

            dns {
                servers = [each.value.nameserver]
            }
        }
    }

    # Start VM after creation
    started = true

    # Ignore changes to cdrom after creation (for ISO-based VMs)
    lifecycle {
        # Terraform requires this to be a static list (no conditionals here).
        # This prevents perpetual drift if Proxmox/provider adjusts CDROM metadata.
        ignore_changes = [cdrom]
    }
}
