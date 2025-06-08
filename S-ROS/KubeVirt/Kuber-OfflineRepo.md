برای راه‌اندازی یک ریپوزیتوری آفلاین برای کوبرنتیز نسخه 1.30.13 که شامل تمام ایمیج‌های مورد نیاز باشد، باید مراحل زیر را به ترتیب انجام دهید. این راهنما فرض می‌کند که شما از ابزاری مانند `kubeadm` برای نصب کوبرنتیز استفاده می‌کنید و می‌خواهید ایمیج‌ها را به صورت آفلاین در یک ریپوزیتوری محلی ذخیره کنید. این روش به خصوص در محیط‌هایی که دسترسی به اینترنت محدود است یا به دلایل امنیتی نیاز به آفلاین بودن دارید، مفید است.

### پیش‌نیازها
- **سیستم‌عامل**: اوبونتو 20.04 یا بالاتر، CentOS 8 یا مشابه.
- **ابزارها**: `docker` یا `containerd` به عنوان runtime کانتینر، `kubeadm`، `kubectl`، و `kubelet` نصب‌شده.
- **دسترسی root**: برای اجرای دستورات.
- **فضای ذخیره‌سازی**: فضای کافی برای ذخیره ایمیج‌ها (حداقل چند گیگابایت بسته به تعداد ایمیج‌ها).
- **یک سرور یا ماشین محلی**: برای میزبانی ریپوزیتوری آفلاین.

### مراحل راه‌اندازی ریپوزیتوری آفلاین

#### 1. **شناسایی ایمیج‌های مورد نیاز برای کوبرنتیز 1.30.13**
کوبرنتیز از ایمیج‌های مختلفی برای اجزای خود (مانند `kube-apiserver`، `kube-controller-manager`، `kube-scheduler`، `kube-proxy`، `etcd`، و غیره) استفاده می‌کند. برای نسخه 1.30.13، می‌توانید لیست ایمیج‌های مورد نیاز را با دستور زیر دریافت کنید:
```bash
kubeadm config images list --kubernetes-version=v1.30.13
```
این دستور لیستی از ایمیج‌ها را نمایش می‌دهد، مانند:
```
registry.k8s.io/kube-apiserver:v1.30.13
registry.k8s.io/kube-controller-manager:v1.30.13
registry.k8s.io/kube-scheduler:v1.30.13
registry.k8s.io/kube-proxy:v1.30.13
registry.k8s.io/pause:3.10
registry.k8s.io/etcd:3.5.13-0
registry.k8s.io/coredns/coredns:v1.11.1
```
**نکته**: اگر به CNI (مانند Calico، Flannel یا Weave) نیاز دارید، باید ایمیج‌های مربوط به آن‌ها را نیز دانلود کنید.

#### 2. **دانلود ایمیج‌ها**
در یک سیستم با دسترسی به اینترنت، ایمیج‌ها را دانلود کنید:
```bash
kubeadm config images pull --kubernetes-version=v1.30.13
```
این دستور تمام ایمیج‌های مورد نیاز برای نسخه 1.30.13 را از `registry.k8s.io` دانلود می‌کند و در رجیستری محلی داکر یا containerd ذخیره می‌کند.

برای CNI (مثلاً Calico)، باید ایمیج‌های مربوط به آن را به صورت دستی دانلود کنید. به عنوان مثال، برای Calico:
```bash
docker pull docker.io/calico/cni:v3.27.0
docker pull docker.io/calico/node:v3.27.0
docker pull docker.io/calico/kube-controllers:v3.27.0
```
**نکته**: نسخه‌های ایمیج‌های CNI را بر اساس سازگاری با کوبرنتیز 1.30.13 بررسی کنید.

#### 3. **ذخیره ایمیج‌ها به صورت فایل**
پس از دانلود ایمیج‌ها، آن‌ها را به صورت فایل‌های tar ذخیره کنید:
```bash
# لیست ایمیج‌ها
docker images

# ذخیره هر ایمیج به صورت فایل tar
docker save -o kube-apiserver-v1.30.13.tar registry.k8s.io/kube-apiserver:v1.30.13
docker save -o kube-controller-manager-v1.30.13.tar registry.k8s.io/kube-controller-manager:v1.30.13
docker save -o kube-scheduler-v1.30.13.tar registry.k8s.io/kube-scheduler:v1.30.13
docker save -o kube-proxy-v1.30.13.tar registry.k8s.io/kube-proxy:v1.30.13
docker save -o pause-3.10.tar registry.k8s.io/pause:3.10
docker save -o etcd-3.5.13-0.tar registry.k8s.io/etcd:3.5.13-0
docker save -o coredns-v1.11.1.tar registry.k8s.io/coredns/coredns:v1.11.1
# برای Calico (در صورت استفاده)
docker save -o calico-cni-v3.27.0.tar docker.io/calico/cni:v3.27.0
docker save -o calico-node-v3.27.0.tar docker.io/calico/node:v3.27.0
docker save -o calico-kube-controllers-v3.27.0.tar docker.io/calico/kube-controllers:v3.27.0
```
این فایل‌های tar را به یک دایرکتوری (مثلاً `/path/to/images`) منتقل کنید.

#### 4. **انتقال ایمیج‌ها به محیط آفلاین**
فایل‌های tar را به سرور یا ماشین آفلاین منتقل کنید (مثلاً با استفاده از USB، SCP یا هر روش دیگر):
```bash
scp *.tar user@offline-server:/path/to/images
```

#### 5. **راه‌اندازی یک رجیستری محلی**
برای میزبانی ایمیج‌ها در محیط آفلاین، می‌توانید یک رجیستری محلی با استفاده از Docker Registry راه‌اندازی کنید:
1. **نصب و اجرای Docker Registry**:
   در سرور آفلاین، یک کانتینر رجیستری محلی اجرا کنید:
   ```bash
   docker run -d -p 5000:5000 --name registry registry:2
   ```
   این دستور یک رجیستری محلی روی پورت 5000 راه‌اندازی می‌کند.

2. **بارگذاری ایمیج‌ها در رجیستری محلی**:
   در سرور آفلاین، ایمیج‌ها را از فایل‌های tar به رجیستری محلی وارد کنید:
   ```bash
   # وارد کردن ایمیج‌ها به داکر
   docker load -i /path/to/images/kube-apiserver-v1.30.13.tar
   docker load -i /path/to/images/kube-controller-manager-v1.30.13.tar
   # ... برای بقیه ایمیج‌ها

   # تگ کردن ایمیج‌ها برای رجیستری محلی
   docker tag registry.k8s.io/kube-apiserver:v1.30.13 localhost:5000/kube-apiserver:v1.30.13
   docker tag registry.k8s.io/kube-controller-manager:v1.30.13 localhost:5000/kube-controller-manager:v1.30.13
   # ... برای بقیه ایمیج‌ها

   # ارسال ایمیج‌ها به رجیستری محلی
   docker push localhost:5000/kube-apiserver:v1.30.13
   docker push localhost:5000/kube-controller-manager:v1.30.13
   # ... برای بقیه ایمیج‌ها
   ```

#### 6. **پیکربندی کوبرنتیز برای استفاده از رجیستری محلی**
برای اینکه `kubeadm` از رجیستری محلی استفاده کند، باید آن را پیکربندی کنید:
1. **تنظیم رجیستری در kubeadm**:
   فایل پیکربندی `kubeadm` را ویرایش کنید تا به رجیستری محلی اشاره کند. یک فایل YAML مانند زیر ایجاد کنید (مثلاً `kubeadm-config.yaml`):
   ```yaml
   apiVersion: kubeadm.k8s.io/v1beta3
   kind: ClusterConfiguration
   kubernetesVersion: v1.30.13
   imageRepository: localhost:5000
   ```
   سپس از این فایل برای مقداردهی اولیه کلاستر استفاده کنید:
   ```bash
   kubeadm init --config kubeadm-config.yaml --pod-network-cidr=10.244.0.0/16
   ```

2. **پیکربندی containerd (در صورت استفاده)**:
   اگر از containerd به جای داکر استفاده می‌کنید، فایل پیکربندی `/etc/containerd/config.toml` را ویرایش کنید:
   ```toml
   [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
     [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.k8s.io"]
       endpoint = ["http://localhost:5000"]
   ```
   سپس containerd را ری‌استارت کنید:
   ```bash
   systemctl restart containerd
   ```

#### 7. **نصب و راه‌اندازی کلاستر کوبرنتیز**
1. **غیرفعال کردن Swap**:
   برای اجرای کوبرنتیز، باید Swap را غیرفعال کنید:
   ```bash
   swapoff -a
   sed -i '/ swap / s/^/#/' /etc/fstab
   ```

2. **نصب kubeadm، kubectl و kubelet**:
   فایل‌های پکیج نسخه 1.30.13 را از قبل دانلود کرده و به سرور آفلاین منتقل کنید:
   ```bash
   apt-get install -y ./kubeadm_1.30.13-*.deb ./kubectl_1.30.13-*.deb ./kubelet_1.30.13-*.deb
   ```

3. **راه‌اندازی کلاستر**:
   با استفاده از فایل پیکربندی، کلاستر را راه‌اندازی کنید:
   ```bash
   kubeadm init --config kubeadm-config.yaml --pod-network-cidr=10.244.0.0/16
   ```

4. **نصب CNI**:
   فایل مانیفست CNI (مثلاً Calico) را دانلود و به سرور آفلاین منتقل کنید:
   ```bash
   kubectl apply -f calico.yaml
   ```

#### 8. **بررسی و تست**
پس از راه‌اندازی، وضعیت کلاستر را بررسی کنید:
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```
اطمینان حاصل کنید که تمام پادها در حالت `Running` هستند.

#### نکات اضافی
- **ذخیره‌سازی پایدار**: اگر قصد استفاده از ذخیره‌سازی پایدار (Persistent Storage) دارید، باید افزونه‌های ذخیره‌سازی مانند NFS یا Ceph را نیز پیکربندی کنید.[](https://www.pardisco.co/blog/open-e/open-e-joviandss/744-%D9%BE%D8%B4%D8%AA%DB%8C%D8%A8%D8%A7%D9%86%DB%8C-%D8%A7%D8%B2-%DA%A9%D9%88%D8%A8%D8%B1%D9%86%D8%AA%DB%8C%D8%B2-%D8%AF%D8%B1-%D9%86%D8%B1%D9%85-%D8%A7%D9%81%D8%B2%D8%A7%D8%B1-open-e)
- **رفع مشکلات تحریم**: اگر در دانلود ایمیج‌ها با مشکل مواجه شدید، از DNSهایی مانند شکن یا 403 استفاده کنید.[](https://ziroday.ir/post/kubeadm-install/)
- **بکاپ‌گیری**: همیشه از ایمیج‌ها و فایل‌های پیکربندی بکاپ تهیه کنید.
- **به‌روزرسانی آفلاین**: برای به‌روزرسانی‌های بعدی، فرآیند دانلود و انتقال ایمیج‌ها را تکرار کنید.



## ========= استفاده از Containerd به جای داکر 

برای راه‌اندازی یک ریپوزیتوری آفلاین برای کوبرنتیز نسخه 1.30.13 با استفاده از `containerd` به جای داکر، باید مراحل مشابهی را طی کنید، اما با ابزارها و دستورات خاص containerd. این راهنما تمام فرآیند را با تمرکز بر containerd توضیح می‌دهد، از دانلود ایمیج‌ها تا راه‌اندازی کلاستر در یک محیط آفلاین. فرض می‌کنیم شما از `kubeadm` برای نصب کوبرنتیز استفاده می‌کنید و به یک رجیستری محلی برای میزبانی ایمیج‌ها نیاز دارید.

### پیش‌نیازها
- **سیستم‌عامل**: اوبونتو 20.04 یا بالاتر، CentOS 8 یا مشابه.
- **ابزارها**: `containerd` به عنوان runtime کانتینر، `kubeadm`، `kubectl`، و `kubelet` نصب‌شده.
- **ابزار اضافی**: `crictl` برای مدیریت ایمیج‌ها و کانتینرها در containerd.
- **دسترسی root**: برای اجرای دستورات.
- **فضای ذخیره‌سازی**: فضای کافی برای ذخیره ایمیج‌ها (حداقل چند گیگابایت).
- **یک سرور یا ماشین محلی**: برای میزبانی ریپوزیتوری آفلاین.

### مراحل راه‌اندازی ریپوزیتوری آفلاین با containerd

#### 1. **شناسایی ایمیج‌های مورد نیاز برای کوبرنتیز 1.30.13**
برای نسخه 1.30.13، لیست ایمیج‌های مورد نیاز را با دستور زیر دریافت کنید:
```bash
kubeadm config images list --kubernetes-version=v1.30.13
```
خروجی شامل ایمیج‌هایی مانند موارد زیر خواهد بود:
```
registry.k8s.io/kube-apiserver:v1.30.13
registry.k8s.io/kube-controller-manager:v1.30.13
registry.k8s.io/kube-scheduler:v1.30.13
registry.k8s.io/kube-proxy:v1.30.13
registry.k8s.io/pause:3.10
registry.k8s.io/etcd:3.5.13-0
registry.k8s.io/coredns/coredns:v1.11.1
```
**نکته**: اگر از CNI مانند Calico استفاده می‌کنید، ایمیج‌های آن (مانند `docker.io/calico/cni:v3.27.0`) را نیز باید دانلود کنید.

#### 2. **دانلود ایمیج‌ها با containerd**
در یک سیستم با دسترسی به اینترنت، از `ctr` (ابزار خط فرمان containerd) برای دانلود ایمیج‌ها استفاده کنید:
1. **نصب containerd** (در صورت عدم نصب):
   ```bash
   apt-get update
   apt-get install -y containerd
   ```
   یا برای CentOS:
   ```bash
   yum install -y containerd
   ```

2. **دانلود ایمیج‌ها**:
   برای هر ایمیج، از دستور `ctr` استفاده کنید:
   ```bash
   ctr -n k8s.io images pull registry.k8s.io/kube-apiserver:v1.30.13
   ctr -n k8s.io images pull registry.k8s.io/kube-controller-manager:v1.30.13
   ctr -n k8s.io images pull registry.k8s.io/kube-scheduler:v1.30.13
   ctr -n k8s.io images pull registry.k8s.io/kube-proxy:v1.30.13
   ctr -n k8s.io images pull registry.k8s.io/pause:3.10
   ctr -n k8s.io images pull registry.k8s.io/etcd:3.5.13-0
   ctr -n k8s.io images pull registry.k8s.io/coredns/coredns:v1.11.1
   # برای Calico (در صورت استفاده)
   ctr -n k8s.io images pull docker.io/calico/cni:v3.27.0
   ctr -n k8s.io images pull docker.io/calico/node:v3.27.0
   ctr -n k8s.io images pull docker.io/calico/kube-controllers:v3.27.0
   ```
   **نکته**: گزینه `-n k8s.io` مشخص می‌کند که ایمیج‌ها در namespace مربوط به کوبرنتیز ذخیره شوند.

3. **بررسی ایمیج‌ها**:
   برای اطمینان از دانلود صحیح، لیست ایمیج‌ها را بررسی کنید:
   ```bash
   ctr -n k8s.io images ls
   ```

#### 3. **ذخیره ایمیج‌ها به صورت فایل**
ایمیج‌ها را به صورت فایل‌های tar ذخیره کنید تا بتوانید آن‌ها را به محیط آفلاین منتقل کنید:
```bash
ctr -n k8s.io images export kube-apiserver-v1.30.13.tar registry.k8s.io/kube-apiserver:v1.30.13
ctr -n k8s.io images export kube-controller-manager-v1.30.13.tar registry.k8s.io/kube-controller-manager:v1.30.13
ctr -n k8s.io images export kube-scheduler-v1.30.13.tar registry.k8s.io/kube-scheduler:v1.30.13
ctr -n k8s.io images export kube-proxy-v1.30.13.tar registry.k8s.io/kube-proxy:v1.30.13
ctr -n k8s.io images export pause-3.10.tar registry.k8s.io/pause:3.10
ctr -n k8s.io images export etcd-3.5.13-0.tar registry.k8s.io/etcd:3.5.13-0
ctr -n k8s.io images export coredns-v1.11.1.tar registry.k8s.io/coredns/coredns:v1.11.1
# برای Calico (در صورت استفاده)
ctr -n k8s.io images export calico-cni-v3.27.0.tar docker.io/calico/cni:v3.27.0
ctr -n k8s.io images export calico-node-v3.27.0.tar docker.io/calico/node:v3.27.0
ctr -n k8s.io images export calico-kube-controllers-v3.27.0.tar docker.io/calico/kube-controllers:v3.27.0
```
فایل‌های tar را به یک دایرکتوری (مثلاً `/path/to/images`) منتقل کنید.

```x-shellscript
#!/bin/bash
# Export Kubernetes 1.30.13 images for offline use
ctr -n k8s.io images export kube-apiserver-v1.30.13.tar registry.k8s.io/kube-apiserver:v1.30.13
ctr -n k8s.io images export kube-controller-manager-v1.30.13.tar registry.k8s.io/kube-controller-manager:v1.30.13
ctr -n k8s.io images export kube-scheduler-v1.30.13.tar registry.k8s.io/kube-scheduler:v1.30.13
ctr -n k8s.io images export kube-proxy-v1.30.13.tar registry.k8s.io/kube-proxy:v1.30.13
ctr -n k8s.io images export pause-3.10.tar registry.k8s.io/pause:3.10
ctr -n k8s.io images export etcd-3.5.13-0.tar registry.k8s.io/etcd:3.5.13-0
ctr -n k8s.io images export coredns-v1.11.1.tar registry.k8s.io/coredns/coredns:v1.11.1
# Export Calico images (optional)
ctr -n k8s.io images export calico-cni-v3.27.0.tar docker.io/calico/cni:v3.27.0
ctr -n k8s.io images export calico-node-v3.27.0.tar docker.io/calico/node:v3.27.0
ctr -n k8s.io images export calico-kube-controllers-v3.27.0.tar docker.io/calico/kube-controllers:v3.27.0
```

#### 4. **انتقال ایمیج‌ها به محیط آفلاین**
فایل‌های tar را به سرور آفلاین منتقل کنید (مثلاً با USB یا SCP):
```bash
scp /path/to/images/*.tar user@offline-server:/path/to/images
```

#### 5. **راه‌اندازی رجیستری محلی با containerd**
برای میزبانی ایمیج‌ها در محیط آفلاین، یک رجیستری محلی راه‌اندازی کنید:
1. **دانلود ایمیج رجیستری**:
   در سیستم آنلاین، ایمیج رجیستری را دانلود و ذخیره کنید:
   ```bash
   ctr -n k8s.io images pull docker.io/library/registry:2
   ctr -n k8s.io images export registry-2.tar docker.io/library/registry:2
   ```
   این فایل را نیز به سرور آفلاین منتقل کنید.

2. **بارگذاری و اجرای رجیستری در سرور آفلاین**:
   در سرور آفلاین، ایمیج رجیستری را بارگذاری کنید:
   ```bash
   ctr -n k8s.io images import /path/to/images/registry-2.tar
   ```
   سپس رجیستری را اجرا کنید:
   ```bash
   ctr -n k8s.io run --rm -p 5000:5000 docker.io/library/registry:2 registry
   ```

3. **بارگذاری ایمیج‌ها در رجیستری محلی**:
   ایمیج‌ها را از فایل‌های tar وارد کنید:
   ```bash
   ctr -n k8s.io images import /path/to/images/kube-apiserver-v1.30.13.tar
   ctr -n k8s.io images import /path/to/images/kube-controller-manager-v1.30.13.tar
   # ... برای بقیه ایمیج‌ها
   ```
   ایمیج‌ها را برای رجیستری محلی تگ کنید و به آن ارسال کنید:
   ```bash
   ctr -n k8s.io images tag registry.k8s.io/kube-apiserver:v1.30.13 localhost:5000/kube-apiserver:v1.30.13
   ctr -n k8s.io images push localhost:5000/kube-apiserver:v1.30.13
   # ... برای بقیه ایمیج‌ها
   ```

```x-shellscript
#!/bin/bash
# Import and push images to local registry
ctr -n k8s.io images import /path/to/images/kube-apiserver-v1.30.13.tar
ctr -n k8s.io images import /path/to/images/kube-controller-manager-v1.30.13.tar
ctr -n k8s.io images import /path/to/images/kube-scheduler-v1.30.13.tar
ctr -n k8s.io images import /path/to/images/kube-proxy-v1.30.13.tar
ctr -n k8s.io images import /path/to/images/pause-3.10.tar
ctr -n k8s.io images import /path/to/images/etcd-3.5.13-0.tar
ctr -n k8s.io images import /path/to/images/coredns-v1.11.1.tar
# Import Calico images (optional)
ctr -n k8s.io images import /path/to/images/calico-cni-v3.27.0.tar
ctr -n k8s.io images import /path/to/images/calico-node-v3.27.0.tar
ctr -n k8s.io images import /path/to/images/calico-kube-controllers-v3.27.0.tar

# Tag images for local registry
ctr -n k8s.io images tag registry.k8s.io/kube-apiserver:v1.30.13 localhost:5000/kube-apiserver:v1.30.13
ctr -n k8s.io images tag registry.k8s.io/kube-controller-manager:v1.30.13 localhost:5000/kube-controller-manager:v1.30.13
ctr -n k8s.io images tag registry.k8s.io/kube-scheduler:v1.30.13 localhost:5000/kube-scheduler:v1.30.13
ctr -n k8s.io images tag registry.k8s.io/kube-proxy:v1.30.13 localhost:5000/kube-proxy:v1.30.13
ctr -n k8s.io images tag registry.k8s.io/pause:3.10 localhost:5000/pause:3.10
ctr -n k8s.io images tag registry.k8s.io/etcd:3.5.13-0 localhost:5000/etcd:3.5.13-0
ctr -n k8s.io images tag registry.k8s.io/coredns/coredns:v1.11.1 localhost:5000/coredns:v1.11.1
# Tag Calico images (optional)
ctr -n k8s.io images tag docker.io/calico/cni:v3.27.0 localhost:5000/calico/cni:v3.27.0
ctr -n k8s.io images tag docker.io/calico/node:v3.27.0 localhost:5000/calico/node:v3.27.0
ctr -n k8s.io images tag docker.io/calico/kube-controllers:v3.27.0 localhost:5000/calico/kube-controllers:v3.27.0

# Push images to local registry
ctr -n k8s.io images push localhost:5000/kube-apiserver:v1.30.13
ctr -n k8s.io images push localhost:5000/kube-controller-manager:v1.30.13
ctr -n k8s.io images push localhost:5000/kube-scheduler:v1.30.13
ctr -n k8s.io images push localhost:5000/kube-proxy:v1.30.13
ctr -n k8s.io images push localhost:5000/pause:3.10
ctr -n k8s.io images push localhost:5000/etcd:3.5.13-0
ctr -n k8s.io images push localhost:5000/coredns:v1.11.1
# Push Calico images (optional)
ctr -n k8s.io images push localhost:5000/calico/cni:v3.27.0
ctr -n k8s.io images push localhost:5000/calico/node:v3.27.0
ctr -n k8s.io images push localhost:5000/calico/kube-controllers:v3.27.0
```

#### 6. **پیکربندی کوبرنتیز برای استفاده از رجیستری محلی**
1. **پیکربندی kubeadm**:
   فایل پیکربندی `kubeadm` را برای استفاده از رجیستری محلی تنظیم کنید:
   ```yaml
   apiVersion: kubeadm.k8s.io/v1beta3
   kind: ClusterConfiguration
   kubernetesVersion: v1.30.13
   imageRepository: localhost:5000
   ```

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.30.13
imageRepository: localhost:5000
```

2. **پیکربندی containerd**:
   فایل پیکربندی containerd (`/etc/containerd/config.toml`) را ویرایش کنید:
   ```toml
   [plugins."io.containerd.grpc.v1.cri".registry]
     [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
       [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.k8s.io"]
         endpoint = ["http://localhost:5000"]
       [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
         endpoint = ["http://localhost:5000"]
   ```
   سپس containerd را ری‌استارت کنید:
   ```bash
   systemctl restart containerd
   ```

```toml
[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.k8s.io"]
      endpoint = ["http://localhost:5000"]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
      endpoint = ["http://localhost:5000"]
```

#### 7. **نصب و راه‌اندازی کلاستر کوبرنتیز**
1. **غیرفعال کردن Swap**:
   ```bash
   swapoff -a
   sed -i '/ swap / s/^/#/' /etc/fstab
   ```

2. **نصب kubeadm، kubectl و kubelet**:
   پکیج‌های نسخه 1.30.13 را از قبل دانلود و به سرور آفلاین منتقل کنید:
   ```bash
   apt-get install -y ./kubeadm_1.30.13-*.deb ./kubectl_1.30.13-*.deb ./kubelet_1.30.13-*.deb
   ```

3. **راه‌اندازی کلاستر**:
   با استفاده از فایل پیکربندی، کلاستر را راه‌اندازی کنید:
   ```bash
   kubeadm init --config kubeadm-config.yaml --pod-network-cidr=10.244.0.0/16
   ```

4. **نصب CNI**:
   فایل مانیفست CNI (مثلاً Calico) را دانلود و به سرور آفلاین منتقل کنید، سپس اعمال کنید:
   ```bash
   kubectl apply -f calico.yaml
   ```

#### 8. **بررسی و تست**
وضعیت کلاستر را بررسی کنید:
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```
اطمینان حاصل کنید که تمام پادها در حالت `Running` هستند.

#### نکات اضافی
- **رفع مشکلات تحریم**: برای دانلود ایمیج‌ها در سیستم آنلاین، از DNSهایی مانند شکن یا 403 استفاده کنید.
- **ذخیره‌سازی پایدار**: برای ذخیره‌سازی، افزونه‌هایی مانند NFS یا Ceph را پیکربندی کنید.
- **بکاپ‌گیری**: از فایل‌های tar و پیکربندی‌ها بکاپ تهیه کنید.
- **crictl به جای ctr**: در سرور آفلاین، می‌توانید از `crictl` برای بررسی ایمیج‌ها و کانتینرها استفاده کنید:
  ```bash
  crictl images
  ```

