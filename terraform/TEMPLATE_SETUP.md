# Template Setup Guide for Cloud-Init IP Configuration

This guide will help you prepare your Ubuntu 24.04 VM as a template so that Terraform can configure static IP addresses via cloud-init.

## Step-by-Step Instructions

### 1. Install Required Packages

SSH into your clean VM and run:

```bash
sudo apt update
sudo apt install -y qemu-guest-agent cloud-init
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent
```

### 2. Enable Cloud-Init Network Configuration

Ubuntu 24.04 may have cloud-init network configuration disabled by default. Enable it:

```bash
# Remove any file that disables network configuration
sudo rm -f /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

# Ensure cloud-init can manage network
sudo rm -f /etc/netplan/50-cloud-init.yaml.backup
```

### 3. Remove Static Network Configuration

Remove any existing static network configuration so cloud-init can manage it:

```bash
# Check current netplan config
ls -la /etc/netplan/

# If there's a static config file (like 01-netcfg.yaml), remove or rename it
sudo mv /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.backup 2>/dev/null || true

# Ensure cloud-init netplan config exists (it should be auto-generated)
sudo netplan generate
```

### 4. Clear Machine ID

Each cloned VM needs a unique machine ID. Clear it so it regenerates on first boot:

```bash
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id
```

### 5. Clean Cloud-Init State

Remove cloud-init logs and state so it runs fresh on each clone:

```bash
sudo cloud-init clean --logs --seed
sudo rm -rf /var/lib/cloud/instances/*
```

### 6. Clean Up System

Remove any temporary files and logs:

```bash
# Clean package cache
sudo apt clean
sudo apt autoremove -y

# Remove logs
sudo rm -rf /var/log/*.log
sudo rm -rf /var/log/*.gz
sudo journalctl --vacuum-time=1s

# Remove SSH host keys (they'll be regenerated)
sudo rm -f /etc/ssh/ssh_host_*
```

### 7. Enable QEMU Guest Agent in Proxmox

**IMPORTANT**: Before converting to template, ensure QEMU Guest Agent is enabled in Proxmox:

1. Go to Proxmox Web UI
2. Select your VM
3. Go to **Options** tab (not Hardware)
4. Find **"QEMU Guest Agent"**
5. Set it to **"Enabled"**
6. Click **OK**
7. **Stop and Start the VM** (not just reboot - fully stop then start)

### 8. Verify QEMU Guest Agent is Working

After restart, verify the guest agent is working:

```bash
systemctl status qemu-guest-agent
```

It should show `Active: active (running)`

### 9. Final Check

Verify cloud-init is ready:

```bash
# Check cloud-init status
sudo cloud-init status

# Verify network config will be managed by cloud-init
cat /etc/cloud/cloud.cfg | grep -A 5 "network:"
```

### 10. Shutdown and Convert to Template

1. Shutdown the VM completely:
   ```bash
   sudo shutdown -h now
   ```

2. In Proxmox Web UI:
   - Right-click the VM
   - Select **"Convert to Template"**
   - Confirm the conversion

3. Note the Template VM ID (e.g., `500`) - you'll use this in Terraform

## Verification After Creating VMs from Template

After Terraform creates VMs from this template, verify cloud-init applied the network config:

1. SSH into a VM
2. Check the network configuration:
   ```bash
   ip addr show
   cat /etc/netplan/50-cloud-init.yaml
   ```
3. Check cloud-init logs:
   ```bash
   sudo cat /var/log/cloud-init.log | grep -i network
   sudo cat /var/log/cloud-init-output.log | grep -i network
   ```

## Troubleshooting

If IP addresses still don't apply:

1. **Check cloud-init logs**:
   ```bash
   sudo cat /var/log/cloud-init.log
   sudo cat /var/log/cloud-init-output.log
   ```

2. **Verify netplan config**:
   ```bash
   sudo netplan get
   sudo netplan apply
   ```

3. **Check if cloud-init ran**:
   ```bash
   sudo cloud-init status
   ```

4. **Force cloud-init to rerun** (testing only):
   ```bash
   sudo cloud-init clean --logs --seed
   sudo reboot
   ```

## Quick Reference Command Sequence

Here's the complete command sequence you can copy-paste:

```bash
# Install packages
sudo apt update
sudo apt install -y qemu-guest-agent cloud-init
sudo systemctl enable qemu-guest-agent
sudo systemctl start qemu-guest-agent

# Enable cloud-init network management
sudo rm -f /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
sudo rm -f /etc/netplan/01-netcfg.yaml 2>/dev/null || true

# Clear machine ID
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -s /etc/machine-id /var/lib/dbus/machine-id

# Clean cloud-init
sudo cloud-init clean --logs --seed
sudo rm -rf /var/lib/cloud/instances/*

# Cleanup
sudo apt clean
sudo apt autoremove -y
sudo rm -rf /var/log/*.log /var/log/*.gz
sudo journalctl --vacuum-time=1s
sudo rm -f /etc/ssh/ssh_host_*

# Shutdown
sudo shutdown -h now
```

Then in Proxmox:
1. Enable QEMU Guest Agent in VM Options
2. Stop and Start VM (verify guest agent works)
3. Shutdown VM
4. Convert to Template

