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