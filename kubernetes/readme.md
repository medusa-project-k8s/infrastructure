```bash
talosctl -n 192.168.0.151 apply-config --file worker.yaml --mode auto
talosctl -n 192.168.0.152 apply-config --file worker-2.yaml --mode auto
```

```bash
talosctl -n 192.168.0.151 reboot
talosctl -n 192.168.0.152 reboot
```
Metric server:
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl -n kube-system patch deploy metrics-server --type='json' -p='[
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"},
  {"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"}
]'

kubectl -n kube-system rollout status deploy/metrics-server

kubectl top nodes
kubectl top pods -A
```

