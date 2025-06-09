

    

---

## 🛠 مراحل نصب KubeVirt:

### 1. دریافت نسخه فعلی KubeVirt

```bash
export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | grep tag_name | cut -d '"' -f 4)
```

### 2. نصب KubeVirt Operator

```bash
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
```

### 3. نصب KubeVirt Custom Resource (CR)

```bash
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml
```

### 4. نصب ابزار virtctl

```bash
# برای لینوکس x86_64:
wget https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-linux-amd64
chmod +x virtctl-${KUBEVIRT_VERSION}-linux-amd64
sudo mv virtctl-${KUBEVIRT_VERSION}-linux-amd64 /usr/local/bin/virtctl
```

---

## ✅ بررسی نصب:

بعد از چند دقیقه:

```bash
kubectl get pods -n kubevirt
kubectl get kv kubevirt -n kubevirt -o yaml
```

باید تمام پادها در وضعیت `Running` باشند.

---

## 🎛 نمونه ایجاد یک ماشین مجازی:

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: test-vm
  namespace: default
spec:
  running: false
  template:
    metadata:
      labels:
        kubevirt.io/domain: test-vm
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
        resources:
          requests:
            memory: 512Mi
      volumes:
      - name: containerdisk
        containerDisk:
          image: kubevirt/cirros-container-disk-demo
```

ایجاد VM:

```bash
kubectl apply -f vm.yaml
virtctl start test-vm
```

---

## ✅ بخش ۱: نصب k3s (کلاستر Kubernetes سبک)

### 1. نصب k3s روی سیستم لینوکسی:

```bash
curl -sfL https://get.k3s.io | sh -
```

### 2. بررسی وضعیت نود و سرویس‌ها:

```bash
sudo k3s kubectl get nodes
```

### 3. اضافه کردن `kubectl` به PATH (برای راحتی):

```bash
sudo ln -s /etc/rancher/k3s/k3s.yaml ~/.kube/config
```

یا اگر خطای دسترسی داری:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

---

## ✅ بخش ۲: فعال کردن KVM روی نود 

مطمئن شو CPU از مجازی‌سازی پشتیبانی می‌کند:

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

نصب ماژول‌های KVM:

```bash
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
```

بررسی:

```bash
lsmod | grep kvm
```

---

## ✅ بخش ۳: نصب KubeVirt روی k3s

### 1. گرفتن آخرین نسخه:

```bash
export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | grep tag_name | cut -d '"' -f 4)
```

### 2. نصب Operator و CR:

```bash
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
kubectl create -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml
```

### 3. بررسی نصب:

```bash
kubectl get pods -n kubevirt
```

---

## ✅ بخش ۴: نصب virtctl برای کنترل VM

```bash
wget https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-linux-amd64
chmod +x virtctl-${KUBEVIRT_VERSION}-linux-amd64
sudo mv virtctl-${KUBEVIRT_VERSION}-linux-amd64 /usr/local/bin/virtctl
```

---

## ⚠️ نکته مهم برای k3s + KubeVirt:

در برخی نسخه‌ها نیاز داری `k3s` را با flag زیر اجرا کنی تا KubeVirt به درستی کار کند:

```bash
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb" sh -
```

یا اگر نصب شده، فایل زیر را ویرایش کن:

```bash
sudo nano /etc/systemd/system/k3s.service
```

و فلگ‌ها را در بخش `ExecStart` اضافه کن.

---

## ✅ خلاصه:

|بخش|وضعیت|
|---|---|
|نصب K3s|✅ سریع و ساده|
|فعال‌سازی KVM|✅ برای VMها ضروری|
|نصب KubeVirt|✅ قابل اجرا روی K3s|
|مناسب برای تک‌نود؟|💯 بله (برای توسعه و تست)|

---

