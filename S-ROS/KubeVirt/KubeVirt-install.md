### **پیش‌نیازها**

قبل از شروع نصب KubeVirt، باید مطمئن شوید که سیستم شما شرایط زیر را دارد:

1. **سخت‌افزار:**
    - پردازنده با پشتیبانی از مجازی‌سازی (Intel VT-x یا AMD-V).
    - حداقل 4 گیگابایت RAM (8 گیگابایت یا بیشتر توصیه می‌شود).
    - حداقل 20 گیگابایت فضای ذخیره‌سازی.
    - اتصال به اینترنت برای دانلود بسته‌ها.

2. **سیستم‌عامل:**

	- یک توزیع لینوکس مانند Ubuntu 20.04/22.04 یا CentOS/RHEL 8 به بالا.
	- دسترسی root یا کاربر با امتیازات sudo.

3. **نرم‌افزارهای مورد نیاز:**

- برنامه **Docker** یا **containerd** به‌عنوان Container Runtime.
- برنامه **Kubeadm**، **kubectl** و **kubelet** برای راه‌اندازی خوشه Kubernetes.
- برنامه **libvirt** و **QEMU/KVM** برای مجازی‌سازی ماشین‌ها.
- ابزار **virtctl** برای مدیریت ماشین‌های مجازی.

4. **نرم‌افزارهای مورد نیاز:**
- تنظیمات شبکه برای دسترسی به API سرور Kubernetes.
- پورت‌های مورد نیاز (مانند 6443 برای Kubernetes API و 22 برای SSH) باید باز باشند.

---

### **مراحل نصب و پیاده‌سازی KubeVirt روی دبیان**

#### **گام ۱: آماده‌سازی سرور دبیان**

1. **به‌روزرسانی سیستم‌عامل:**
   سیستم را به‌روز کنید تا از آخرین بسته‌ها و وصله‌های امنیتی استفاده کنید:
   ```bash
   sudo apt update && sudo apt full-upgrade -y
   ```

2. **نصب پیش‌نیازهای اولیه:**
   بسته‌های مورد نیاز برای مجازی‌سازی و Kubernetes را نصب کنید:
   ```bash
   sudo apt install -y curl git vim apt-transport-https ca-certificates gnupg
   ```

3. **فعال‌سازی مجازی‌سازی در CPU:**
   بررسی کنید که پردازنده شما از مجازی‌سازی سخت‌افزاری پشتیبانی می‌کند:
   ```bash
   egrep -c '(vmx|svm)' /proc/cpuinfo
   ```
   اگر خروجی عدد صفر نباشد، CPU از مجازی‌سازی پشتیبانی می‌کند. در غیر این صورت، باید تنظیمات BIOS/UEFI را بررسی کرده و Intel VT-x یا AMD-V را فعال کنید.

4. **نصب libvirt و QEMU/KVM:**
   KubeVirt از KVM برای اجرای ماشین‌های مجازی استفاده می‌کند. بسته‌های لازم را نصب کنید:
   ```bash
   sudo apt install -y libvirt-daemon-system libvirt-clients qemu-kvm
   ```

   سرویس libvirt را فعال و اجرا کنید:
   ```bash
   sudo systemctl enable libvirtd
   sudo systemctl start libvirtd
   ```

5. **بررسی نصب KVM:**
   بررسی کنید که KVM به درستی کار می‌کند:
   ```bash
   sudo apt install -y cpu-checker
   kvm-ok
   ```
   خروجی باید نشان دهد که KVM فعال و قابل استفاده است.

6. **تنظیم کاربر برای libvirt:**
   کاربر خود را به گروه libvirt اضافه کنید تا بدون نیاز به sudo به libvirt دسترسی داشته باشید:
   ```bash
   sudo adduser $(whoami) libvirt
   ```

---

#### **گام ۲: نصب و راه‌اندازی Kubernetes روی دبیان**

1. **نصب containerd:**
   برای مدیریت کانتینرها، containerd را نصب کنید:
   ```bash
   sudo apt install -y containerd
   sudo mkdir -p /etc/containerd
   containerd config default | sudo tee /etc/containerd/config.toml
   ```

   فایل تنظیمات containerd را ویرایش کنید تا از **systemd** به‌عنوان cgroup driver استفاده شود (برای سازگاری با Kubernetes):
   ```bash
   sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
   ```

   سرویس containerd را راه‌اندازی کنید:
   ```bash
   sudo systemctl restart containerd
   sudo systemctl enable containerd
   ```

2. **نصب kubeadm، kubectl و kubelet:**
   مخزن Kubernetes را به سیستم اضافه کنید:
   ```bash
   curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
   echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
   sudo apt update
   sudo apt install -y kubelet kubeadm kubectl
   sudo apt-mark hold kubelet kubeadm kubectl
   ```

   **توجه:** نسخه 1.28 در زمان نگارش این متن پایدار است. برای نسخه‌های جدیدتر، آدرس مخزن را از سایت رسمی Kubernetes بررسی کنید.

3. **غیرفعال کردن Swap:**
   Kubernetes با Swap کار نمی‌کند، بنابراین آن را غیرفعال کنید:
   ```bash
   sudo swapoff -a
   sudo sed -i '/ swap / s/^/#/' /etc/fstab
   ```

4. **راه‌اندازی خوشه Kubernetes:**
   خوشه تک‌نودی را با kubeadm راه‌اندازی کنید:
   ```bash
   sudo kubeadm init --pod-network-cidr=192.168.0.0/16
   ```

   پس از اتمام، دستورات نمایش داده شده را اجرا کنید تا فایل تنظیمات kubectl را آماده کنید:
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

5. **نصب پلاگین شبکه (CNI):**
   برای شبکه پادها، پلاگین Calico را نصب کنید:
   ```bash
   kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
   ```

6. **بررسی وضعیت خوشه:**
   مطمئن شوید که خوشه به درستی کار می‌کند:
   ```bash
   kubectl get nodes
   ```
   خروجی باید نود شما را با وضعیت **Ready** نشان دهد.

---

#### **گام ۳: نصب KubeVirt**

1. **دانلود و نصب اپراتور KubeVirt:**
   آخرین نسخه KubeVirt را از مخزن GitHub پروژه دریافت کنید:
   ```bash
   export KUBEVIRT_VERSION=$(curl -s https://api.github.com/repos/kubevirt/kubevirt/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
   kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-operator.yaml
   ```

2. **ایجاد منبع KubeVirt:**
   یک منبع KubeVirt ایجاد کنید تا مؤلفه‌های لازم مستقر شوند:
   ```bash
   kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/kubevirt-cr.yaml
   ```

3. **بررسی وضعیت استقرار KubeVirt:**
   منتظر بمانید تا تمام پادهای KubeVirt در namespace **kubevirt** آماده شوند:
   ```bash
   kubectl get pods -n kubevirt
   ```
   همه پادها باید در حالت **Running** باشند.

4. **نصب virtctl:**
   ابزار **virtctl** برای مدیریت ماشین‌های مجازی استفاده می‌شود:
   ```bash
   curl -L -o virtctl https://github.com/kubevirt/kubevirt/releases/download/${KUBEVIRT_VERSION}/virtctl-${KUBEVIRT_VERSION}-linux-amd64
   chmod +x virtctl
   sudo mv virtctl /usr/local/bin/
   ```

---

#### **گام ۴: آزمایش KubeVirt با ایجاد یک ماشین مجازی**

برای اطمینان از عملکرد صحیح KubeVirt، یک ماشین مجازی نمونه ایجاد کنید:

1. **ایجاد یک فایل YAML برای ماشین مجازی:**
   یک فایل به نام `vm.yaml` با محتوای زیر ایجاد کنید:
   ```yaml
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
               #cloud-config
               password: cirros
               chpasswd: { expire: False }
   ```

2. **اعمال فایل YAML:**
   ماشین مجازی را با استفاده از kubectl ایجاد کنید:
   ```bash
   kubectl apply -f vm.yaml
   ```

3. **بررسی ماشین مجازی:**
   وضعیت ماشین مجازی را بررسی کنید:
   ```bash
   kubectl get vms
   kubectl get vmi
   ```

4. **دسترسی به ماشین مجازی با virtctl:**
   برای دسترسی به کنسول ماشین مجازی:
   ```bash
   virtctl console test-vm
   ```
   با استفاده از نام کاربری `cirros` و رمز عبور `cirros` وارد شوید.

---

#### **گام ۵: پیکربندی ذخیره‌سازی و شبکه (اختیاری)**

1. **تنظیم ذخیره‌سازی پایدار:**
   برای ذخیره‌سازی پایدار، یک **StorageClass** و **PersistentVolumeClaim (PVC)** تنظیم کنید. به عنوان مثال:
   ```yaml
   apiVersion: storage.k8s.io/v1
   kind: StorageClass
   metadata:
     name: local-storage
   provisioner: kubernetes.io/no-provisioner
   volumeBindingMode: WaitForFirstConsumer
   ---
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: pv-example
   spec:
     capacity:
       storage: 10Gi
     accessModes:
       - ReadWriteOnce
     persistentVolumeReclaimPolicy: Retain
     storageClassName: local-storage
     local:
       path: /mnt/disks/disk1
     nodeAffinity:
       required:
         nodeSelectorTerms:
         - matchExpressions:
           - key: kubernetes.io/hostname
             operator: In
             values:
             - <your-node-name>
   ```

   برای یافتن نام نود، از دستور زیر استفاده کنید:
   ```bash
   kubectl get nodes
   ```

   سپس PVC را به ماشین مجازی اضافه کنید:
   ```yaml
   - name: pv-disk
     persistentVolumeClaim:
       claimName: <pvc-name>
   ```

2. **تنظیم شبکه:**
   KubeVirt به‌طور پیش‌فرض از شبکه‌های CNI مانند Calico پشتیبانی می‌کند. برای تنظیمات پیشرفته‌تر (مانند SR-IOV)، باید پلاگین‌های مربوطه را نصب کنید.

---

#### **گام ۶: بررسی و عیب‌یابی**

1. **بررسی لاگ‌ها:**
   اگر مشکلی پیش آمد، لاگ‌های پادهای KubeVirt را بررسی کنید:
   ```bash
   kubectl logs <pod-name> -n kubevirt
   ```

2. **بررسی منابع:**
   منابع ماشین‌های مجازی و پادها را بررسی کنید:
   ```bash
   kubectl describe vmi test-vm
   ```

3. **تست دسترسی به ماشین مجازی:**
   برای دسترسی به ماشین مجازی از طریق شبکه، می‌توانید یک سرویس Kubernetes ایجاد کنید:
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: test-vm-service
   spec:
     ports:
     - port: 22
       targetPort: 22
       protocol: TCP
     selector:
       kubevirt.io/vm: test-vm
     type: NodePort
   ```

---

### **نکات مهم برای دبیان**

- **مدیریت بسته‌ها:** در دبیان، از `apt` برای مدیریت بسته‌ها استفاده کنید و مطمئن شوید که مخازن به‌روز هستند.
- **فایروال:** اگر از فایروال (مانند `ufw`) استفاده می‌کنید، پورت‌های مورد نیاز Kubernetes (مانند 6443، 10250) و libvirt را باز کنید:
   ```bash
   sudo ufw allow 6443
   sudo ufw allow 10250
   sudo ufw allow 22
   ```
- **عملکرد در دبیان:** دبیان به دلیل پایداری بالا برای محیط‌های تولید مناسب است، اما مطمئن شوید که درایورهای مناسب برای سخت‌افزار (مانند کارت شبکه یا GPU) نصب شده‌اند.
- **ذخیره‌سازی:** اگر از ذخیره‌سازی محلی استفاده می‌کنید، دایرکتوری‌هایی مانند `/mnt/disks` را ایجاد کرده و دسترسی‌های لازم را تنظیم کنید.

---

### **منابع**

- مستندات رسمی KubeVirt: https://kubevirt.io/user-guide/
- مخزن GitHub پروژه KubeVirt: https://github.com/kubevirt/kubevirt
- آموزش نصب Kubernetes روی دبیان: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

---

