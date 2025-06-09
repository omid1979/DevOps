#!/bin/bash

set -e

echo "🔧 شروع نصب K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb" sh -

echo "🔗 اتصال kubectl به k3s..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

echo "🧠 بررسی نود K3s:"
kubectl get nodes

echo "📦 نصب Longhorn Storage..."
kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.6.0/deploy/longhorn.yaml

echo "⏳ صبر برای آماده شدن Longhorn..."
sleep 60
kubectl -n longhorn-system wait --for=condition=Ready pods --all --timeout=180s

echo "📥 دریافت آخرین نسخه KubeVirt..."
export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | grep tag_name | cut -d '"' -f 4)

echo "📦 نصب KubeVirt Operator و CR..."
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml

echo "⏳ صبر برای آماده شدن KubeVirt..."
sleep 60
kubectl -n kubevirt wait --for=condition=Ready pods --all --timeout=180s

echo "🛠 نصب ابزار virtctl..."
wget https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-linux-amd64
chmod +x virtctl-${KUBEVIRT_VERSION}-linux-amd64
sudo mv virtctl-${KUBEVIRT_VERSION}-linux-amd64 /usr/local/bin/virtctl

echo "✅ نصب با موفقیت انجام شد!"
echo "➡ Longhorn UI: اجرا کنید → kubectl -n longhorn-system port-forward svc/longhorn-frontend 8080:80"
echo "➡ KubeVirt آماده است. می‌توانید VM بسازید."

