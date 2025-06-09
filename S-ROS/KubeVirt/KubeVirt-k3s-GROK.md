برای نصب **KubeVirt** با **K3s** روی یک سرور **دبیان** (Debian) برای یک نود Edge، باید مراحل زیر را به ترتیب و با دقت انجام دهید. این راهنما فرض می‌کند که شما یک سرور دبیان (ترجیحاً نسخه 11 یا 12) دارید و می‌خواهید یک محیط تمیز و پایدار برای اجرای ماشین‌های مجازی (VM) با KubeVirt در یک نود Edge راه‌اندازی کنید. در این راهنما، مراحل نصب به صورت کامل و با جزئیات ارائه شده است.

---

### **پیش‌نیازها**
1. **سیستم‌عامل**: دبیان 11 یا 12 (توصیه می‌شود سرور تازه نصب شده باشد).
2. **سخت‌افزار**:
   - حداقل 2 هسته CPU و 4 گیگابایت RAM (برای نود Edge سبک).
   - پشتیبانی از مجازی‌سازی (VT-x/AMD-V) در CPU (برای اجرای VMها).
   - فضای دیسک کافی (حداقل 20 گیگابایت برای نصب و VMها).
3. **دسترسی root یا کاربر با امتیازات sudo**.
4. **اتصال اینترنت پایدار** برای دانلود پکیج‌ها.
5. **نرم‌افزارهای مورد نیاز**:
   - `curl`, `git`, `sudo`, `qemu-kvm`, `libvirt-daemon-system`, `virtinst`.
6. **فایروال و SELinux**: اطمینان حاصل کنید که فایروال (مانند `ufw`) یا AppArmor تنظیمات خاصی برای محدود کردن K3s یا KubeVirt ندارد. برای سادگی، ممکن است بخواهید فایروال را موقتاً غیرفعال کنید.

---

### **مرحله ۱: آماده‌سازی سرور دبیان**
1. **به‌روزرسانی سیستم**:
   سیستم را به‌روز کنید تا از آخرین بسته‌ها استفاده کنید:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **نصب پیش‌نیازها**:
   ابزارهای مورد نیاز برای نصب و مدیریت را نصب کنید:
   ```bash
   sudo apt install -y curl git vim
   ```

3. **غیرفعال کردن Swap**:
   KubeVirt و K3s برای عملکرد بهتر نیاز به غیرفعال کردن Swap دارند:
   ```bash
   sudo swapoff -a
   sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
   ```

4. **نصب و بررسی KVM**:
   KubeVirt برای اجرای ماشین‌های مجازی به KVM نیاز دارد:
   ```bash
   sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst
   ```
   بررسی کنید که KVM به درستی کار می‌کند:
   ```bash
   kvm-ok
   ```
   اگر خروجی نشان داد که مجازی‌سازی پشتیبانی می‌شود، ادامه دهید. در غیر این صورت، باید مجازی‌سازی را در BIOS/UEFI سرور فعال کنید.

5. **فعال‌سازی ماژول‌های کرنل**:
   اطمینان حاصل کنید که ماژول‌های مورد نیاز برای KVM بارگذاری شده‌اند:
   ```bash
   sudo modprobe kvm
   sudo modprobe kvm_intel  # برای پردازنده‌های اینتل
   sudo modprobe kvm_amd    # برای پردازنده‌های AMD
   ```
   برای بارگذاری دائمی این ماژول‌ها:
   ```bash
   echo "kvm" | sudo tee -a /etc/modules
   echo "kvm_intel" | sudo tee -a /etc/modules  # یا kvm_amd
   ```

---

### **مرحله ۲: نصب K3s**
K3s یک توزیع سبک از Kubernetes است که برای محیط‌های Edge مناسب است.

1. **دانلود و نصب K3s**:
   K3s را با استفاده از اسکریپت رسمی نصب کنید. برای نصب به عنوان یک نود مستقل (single-node):
   ```bash
   curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --disable traefik
   ```
   توضیحات:
   - `--write-kubeconfig-mode 644`: دسترسی به فایل kubeconfig را ساده‌تر می‌کند.
   - `--disable traefik`: از نصب Traefik به صورت پیش‌فرض جلوگیری می‌کند (می‌توانید بعداً Ingress دلخواه خود را نصب کنید).

2. **بررسی نصب K3s**:
   بررسی کنید که K3s به درستی نصب شده و در حال اجرا است:
   ```bash
   sudo systemctl status k3s
   ```
   نودهای کلاستر را بررسی کنید:
   ```bash
   kubectl get nodes
   ```
   باید نود شما با وضعیت `Ready` نمایش داده شود.

3. **تنظیم دسترسی به kubectl**:
   برای استفاده از `kubectl` به عنوان کاربر غیر-root:
   ```bash
   mkdir -p $HOME/.kube
   sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   export KUBECONFIG=$HOME/.kube/config
   ```
   برای دائمی کردن متغیر محیطی، خط زیر را به `~/.bashrc` اضافه کنید:
   ```bash
   echo 'export KUBECONFIG=$HOME/.kube/config' >> ~/.bashrc
   source ~/.bashrc
   ```

---

### **مرحله ۳: نصب KubeVirt**
KubeVirt به شما امکان می‌دهد ماشین‌های مجازی را در کنار کانتینرها در Kubernetes مدیریت کنید.

1. **نصب اپراتور KubeVirt**:
   آخرین نسخه پایدار KubeVirt را نصب کنید. ابتدا نسخه مناسب را از مخزن GitHub پروژه بررسی کنید:
   ```bash
   export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
   ```
   اپراتور KubeVirt را اعمال کنید:
   ```bash
   kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
   ```

2. **نصب CRDهای KubeVirt**:
   Custom Resource Definitions (CRDs) را نصب کنید:
   ```bash
   kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml
   ```

3. **بررسی وضعیت نصب KubeVirt**:
   منتظر بمانید تا تمام پادهای KubeVirt در namespace `kubevirt` آماده شوند:
   ```bash
   kubectl get pods -n kubevirt
   ```
   اگر همه پادها در وضعیت `Running` باشند، نصب موفق بوده است.

4. **نصب virtctl**:
   ابزار `virtctl` برای مدیریت ماشین‌های مجازی استفاده می‌شود:
   ```bash
   export VIRTCTL_VERSION=${KUBEVIRT_VERSION}
   curl -L -o /usr/local/bin/virtctl \
   https://github.com/kubevirt/kubevirt/releases/download/${VIRTCTL_VERSION}/virtctl-${VIRTCTL_VERSION}-linux-amd64
   chmod +x /usr/local/bin/virtctl
   ```

---

### **مرحله ۴: تنظیمات اضافی برای نود Edge**
1. **نصب CDI (Containerized Data Importer)**:
   CDI برای مدیریت دیسک‌های ماشین‌های مجازی مفید است:
   ```bash
   export CDI_VERSION=$(curl -s https://api.github.com/repos/kubevirt/containerized-data-importer/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
   kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-operator.yaml
   kubectl apply -f https://github.com/kubevirt/containerized-data-importer/releases/download/${CDI_VERSION}/cdi-cr.yaml
   ```

2. **فعال‌سازی Emulated TPM (اختیاری)**:
   اگر ماشین‌های مجازی شما نیاز به TPM (Trusted Platform Module) دارند، ویژگی emulation را فعال کنید:
   ```bash
   kubectl edit kubevirt -n kubevirt kubevirt
   ```
   در فایل تنظیمات، بخش زیر را اضافه کنید:
   ```yaml
   spec:
     configuration:
       developerConfiguration:
         featureGates:
         - TPMv2
   ```

3. **تنظیم شبکه (اختیاری)**:
   برای نود Edge، ممکن است نیاز به تنظیم شبکه خاص (مانند Multus یا Flannel) داشته باشید. به صورت پیش‌فرض، K3s از Flannel استفاده می‌کند. اگر نیاز به تنظیمات پیشرفته دارید، به مستندات K3s مراجعه کنید.

---

### **مرحله ۵: تست نصب با یک ماشین مجازی**
1. **ایجاد یک ماشین مجازی ساده**:
   یک فایل YAML برای تعریف یک VM ایجاد کنید:
   ```bash
   cat <<EOF > test-vm.yaml
   apiVersion: kubevirt.io/v1
   kind: VirtualMachine
   metadata:
     name: test-vm
   spec:
     running: true
     template:
       metadata:
         labels:
           kubevirt.io/vm: test-vm
       spec:
         domain:
           devices:
             disks:
             - disk:
                 bus: virtio
               name: containerdisk
             - disk:
                 bus: virtio
               name: cloudinitdisk
           resources:
             requests:
               memory: 512Mi
         volumes:
         - name: containerdisk
           containerDisk:
             image: quay.io/kubevirt/cirros-container-disk-demo
         - name: cloudinitdisk
           cloudInitNoCloud:
             userData: |
               #!/bin/sh
               echo "KubeVirt test VM"
   EOF
   ```
   VM را اعمال کنید:
   ```bash
   kubectl apply -f test-vm.yaml
   ```

2. **بررسی ماشین مجازی**:
   وضعیت VM را بررسی کنید:
   ```bash
   kubectl get vms
   virtctl start test-vm
   ```
   برای اتصال به VM:
   ```bash
   virtctl console test-vm
   ```

---

### **مرحله ۶: عیب‌یابی و نکات مهم**
1. **بررسی لاگ‌ها**:
   اگر مشکلی پیش آمد، لاگ‌های K3s و KubeVirt را بررسی کنید:
   ```bash
   sudo journalctl -u k3s
   kubectl logs -n kubevirt <pod-name>
   ```

2. **تنظیمات فایروال**:
   برای نود Edge، پورت‌های مورد نیاز K3s و KubeVirt را باز کنید:
   ```bash
   sudo ufw allow 6443/tcp  # برای API سرور K3s
   sudo ufw allow 10250/tcp # برای Kubelet
   sudo ufw allow 8472/udp  # برای Flannel
   ```

3. **بهینه‌سازی برای Edge**:
   - از تصاویر سبک (مانند CirrOS) برای VMها استفاده کنید.
   - منابع سرور (CPU و RAM) را با توجه به نیازهای نود Edge مدیریت کنید.
   - برای پایداری بیشتر، از نسخه‌های پایدار K3s و KubeVirt استفاده کنید.


---
نحوه استفاده از Calico به جای Flannel

اگر می‌خواهید از Calico به عنوان CNI استفاده کنید، مراحل زیر را به جای نصب پیش‌فرض K3s دنبال کنید:

    نصب K3s بدون CNI پیش‌فرض: برای غیرفعال کردن Flannel در هنگام نصب K3s:
    bash

curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644 --disable traefik --disable-network-policy --flannel-backend=none
توضیحات:

    --disable-network-policy: سیاست‌های شبکه پیش‌فرض را غیرفعال می‌کند.
    --flannel-backend=none: Flannel را غیرفعال می‌کند تا بتوانید CNI دیگری مانند Calico نصب کنید.

نصب Calico: فایل مانیفست Calico را دانلود و اعمال کنید:
bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
یا اگر نسخه خاصی از Calico مد نظر دارید، نسخه مورد نظر را از مستندات رسمی Calico انتخاب کنید.
بررسی نصب Calico: مطمئن شوید که پادهای Calico در namespace calico-system در حال اجرا هستند:
bash
kubectl get pods -n calico-system
تنظیم فایروال برای Calico: Calico از پروتکل BGP (پورت 179/TCP) یا VXLAN (پورت 4789/UDP) استفاده می‌کند. پورت‌های مربوطه را در فایروال باز کنید:
bash
sudo ufw allow 179/tcp
sudo ufw allow 4789/udp
بررسی شبکه: اطمینان حاصل کنید که نودها و پادها به درستی با هم ارتباط برقرار می‌کنند:
bash

    kubectl get nodes
    kubectl get pods -A

---

### **منابع و مستندات**
- مستندات رسمی K3s: [https://docs.k3s.io](https://docs.k3s.io)
- مستندات رسمی KubeVirt: [https://kubevirt.io/user-guide/](https://kubevirt.io/user-guide/)
- مخزن GitHub پروژه KubeVirt: [https://github.com/kubevirt/kubevirt](https://github.com/kubevirt/kubevirt)

---

### **جمع‌بندی**
با اجرای این مراحل، شما یک محیط K3s با KubeVirt روی سرور دبیان خود خواهید داشت که برای اجرای ماشین‌های مجازی در یک نود Edge مناسب است. این راهنما سعی کرده تمام جنبه‌های نصب را به صورت تمیز و کامل پوشش دهد. اگر سوال یا مشکلی در هر مرحله داشتید، جزئیات خطا را به اشتراک بگذارید تا بتوانم دقیق‌تر راهنمایی کنم.


