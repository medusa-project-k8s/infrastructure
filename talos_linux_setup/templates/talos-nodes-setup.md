talosctl --nodes <node-ip-address> get links --insecure

talosctl get disks --insecure --nodes $CONTROL_PLANE_IP

talosctl gen config $CLUSTER_NAME https://$CONTROL_PLANE_IP:6443 --install-disk /dev/$DISK_NAME

talosctl apply-config --insecure --nodes $CONTROL_PLANE_IP --file controlplane.yaml

for ip in "${WORKER_IP[@]}"; do
    echo "Applying config to worker node: $ip"
    talosctl apply-config --insecure --nodes "$ip" --file worker.yaml
done

talosctl bootstrap --nodes $CONTROL_PLANE_IP --talosconfig=./talosconfig

talosctl kubeconfig --nodes $CONTROL_PLANE_IP --talosconfig=./talosconfig




export TALOSCONFIG="$(pwd)/talosconfig"

talosctl gen config Medusa-cluster https://192.168.0.150:6443 \
  --config-patch-control-plane @cp.yaml \
  --config-patch-worker @wp.yaml \
  --force


talosctl patch --mode=no-reboot machineconfig -n 192.168.0.150 --patch @cp.yaml

talosctl patch --mode=no-reboot machineconfig -n 192.168.0.151 --patch @wp.yaml

talosctl patch --mode=no-reboot machineconfig -n 192.168.0.152 --patch @wp.yaml

Verify patches and node health:
  talosctl -n 192.168.0.150 health
  talosctl -n 192.168.0.151 health
  talosctl -n 192.168.0.152 health
  talosctl -n 192.168.0.150 get machineconfig -o yaml   # confirm cp.yaml content is present
  talosctl -n 192.168.0.151 get machineconfig -o yaml   # confirm wp.yaml content is present
  kubectl get nodes -o wide

IMPORTANT

Restart kubelet or reboot the node if you modify the vm.nr_hugepages configuration of a node. Replicated PV Mayastor will not deploy correctly if the available Huge Page count as reported by the node's kubelet instance does not meet the minimum requirements.

talosctl -n <node ip> service kubelet restart