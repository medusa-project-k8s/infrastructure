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

```bash

# 1. Strict ARP (if kube-proxy IPVS or to be safe)
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e 's/strictARP: false/strictARP: true/' | kubectl apply -f - -n kube-system
kubectl -n kube-system rollout restart daemonset/kube-proxy
kubectl -n kube-system rollout status daemonset/kube-proxy

# 2. Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

# 3. Wait for MetalLB
kubectl -n metallb-system rollout status daemonset/speaker
kubectl -n metallb-system rollout status deployment/controller

# 4. Apply your pool (from repo kubernetes/ dir)
kubectl apply -f metallb-pool.yaml

kubectl get pods -n metallb-system
kubectl -n metallb-system get svc
kubectl delete validatingwebhookconfiguration metallb-webhook-configuration
kubectl apply -f metallb-pool.yaml