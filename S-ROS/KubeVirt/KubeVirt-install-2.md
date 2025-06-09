نصب و راه اندازی رابط وب برای کلاستر کوبرنتیز

برای راه‌اندازی داشبورد مدیریتی Kubernetes به منظور مدیریت کلاستر Kubernetes و KubeVirt، باید مراحل زیر را به ترتیب انجام دهید. 
ین راهنما فرض می‌کند که شما یک کلاستر Kubernetes فعال دارید و KubeVirt روی آن نصب شده است. در ادامه، مراحل نصب و پیکربندی داشبورد Kubernetes به صورت کامل توضیح داده شده است:

---

### **پیش‌نیازها**
1. **کلاستر Kubernetes فعال**: مطمئن شوید که یک کلاستر Kubernetes در حال اجرا دارید (می‌توانید از ابزارهایی مثل `kubeadm`، `Minikube` یا سرویس‌های ابری مثل GKE، EKS یا AKS استفاده کنید).
2. **نصب kubectl**: ابزار خط فرمان `kubectl` باید روی سیستم شما نصب و پیکربندی شده باشد تا با کلاستر ارتباط برقرار کند.
3. **نصب KubeVirt**: اگر قصد مدیریت KubeVirt را دارید، باید KubeVirt روی کلاستر نصب شده باشد.
4. **دسترسی به سرور Master**: دسترسی به نود اصلی (Master Node) برای اجرای دستورات مورد نیاز است.
5. **اتصال اینترنتی**: برای دانلود فایل‌های مورد نیاز داشبورد.

---

### **مرحله ۱: نصب داشبورد Kubernetes**
1. **دانلود و اعمال فایل YAML داشبورد**:
   داشبورد رسمی Kubernetes را می‌توانید با استفاده از فایل YAML پیشنهادی نصب کنید. دستور زیر را در نود اصلی اجرا کنید:

   ```bash
   kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
   ```

   این دستور داشبورد Kubernetes نسخه 2.7.0 (آخرین نسخه پایدار تا تاریخ نگارش) را نصب می‌کند. اگر نسخه جدیدتری منتشر شده، آدرس فایل YAML را از مخزن رسمی Kubernetes بررسی کنید.

2. **بررسی وضعیت نصب**:
   برای اطمینان از نصب صحیح، بررسی کنید که پادهای داشبورد در حال اجرا باشند:

   ```bash
   kubectl get pods -n kubernetes-dashboard
   ```

   خروجی باید پادهایی با وضعیت `Running` نشان دهد.

---

### **مرحله ۲: پیکربندی دسترسی به داشبورد**
برای دسترسی به داشبورد، باید آن را از خارج از کلاستر در دسترس قرار دهید و احراز هویت را تنظیم کنید.

1. **ایجاد حساب خدماتی (Service Account)**:
   برای ورود به داشبورد، نیاز به یک حساب خدماتی با دسترسی‌های مناسب دارید. دستورات زیر را اجرا کنید:

   ```bash
   kubectl create serviceaccount dashboard-admin -n kubernetes-dashboard
   kubectl create clusterrolebinding dashboard-admin-binding --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:dashboard-admin
   ```

   این دستورات یک حساب خدماتی به نام `dashboard-admin` ایجاد کرده و به آن نقش `cluster-admin` تخصیص می‌دهد.

2. **دریافت توکن احراز هویت**:
   برای ورود به داشبورد، به یک توکن نیاز دارید. دستور زیر توکن را استخراج می‌کند:

   ```bash
   kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa dashboard-admin -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
	```
	
دریافت نام Secret مربوط به Service Account:
kubectl -n kubernetes-dashboard get sa dashboard-admin -o jsonpath="{.secrets[0].name}"
		kubectl -n kubernetes-dashboard get sa
				kubectl -n kubernetes-dashboard create sa dashboard-admin

kubectl -n kubernetes-dashboard get secret dashboard-admin-token-xxxxx -o go-template="{{.data.token | base64decode}}"

kubectl -n kubernetes-dashboard get secret
kubectl -n kubernetes-dashboard describe secret dashboard-admin-token-xxxxx

kubectl get namespaces

```
# ایجاد Service Account
kubectl -n kubernetes-dashboard create sa dashboard-admin
# ایجاد Secret برای آن (Kubernetes معمولاً به طور خودکار این کار را انجام می‌دهد)
kubectl -n kubernetes-dashboard apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-admin-token
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: dashboard-admin
type: kubernetes.io/service-account-token
EOF
```
kubectl -n kubernetes-dashboard get pods
kubectl -n kubernetes-dashboard get deployments -o wide
   توکن خروجی را کپی کنید، زیرا برای ورود به داشبورد نیاز است.

3. **دسترسی به داشبورد**:
   به صورت پیش‌فرض، داشبورد روی یک سرویس ClusterIP اجرا می‌شود که از خارج کلاستر قابل دسترسی نیست. برای دسترسی، می‌توانید از یکی از روش‌های زیر استفاده کنید:

   - **روش ۱: استفاده از kubectl proxy** (مناسب برای تست محلی):
     ```bash
     kubectl proxy
     ```
     سپس در مرورگر به آدرس زیر بروید:
     ```
     http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
     ```
     در صفحه ورود، توکنی که در مرحله قبل کپی کردید را وارد کنید.

   - **روش ۲: افشای داشبورد با NodePort** (برای دسترسی از راه دور):
     سرویس داشبورد را ویرایش کنید تا از نوع `NodePort` استفاده کند:
     ```bash
     kubectl edit svc kubernetes-dashboard -n kubernetes-dashboard
     ```
     در فایل باز شده، `type: ClusterIP` را به `type: NodePort` تغییر دهید. سپس پورت تخصیص‌یافته را بررسی کنید:
     ```bash
     kubectl get svc -n kubernetes-dashboard
     ```
     خروجی پورتی (مثلاً 30000) را نشان می‌دهد. حالا می‌توانید از طریق `https://<MASTER_NODE_IP>:<NODE_PORT>` به داشبورد دسترسی پیدا کنید.

   - **روش ۳: استفاده از Ingress** (برای محیط‌های تولید):
     اگر از Ingress Controller (مثل NGINX) استفاده می‌کنید، می‌توانید داشبورد را از طریق یک دامنه و HTTPS در دسترس قرار دهید. یک فایل Ingress مانند زیر ایجاد کنید:

     ```yaml
     apiVersion: networking.k8s.io/v1
     kind: Ingress
     metadata:
       name: dashboard-ingress
       namespace: kubernetes-dashboard
       annotations:
         nginx.ingress.kubernetes.io/secure-backends: "true"
         nginx.ingress.kubernetes.io/ssl-passthrough: "true"
     spec:
       rules:
       - host: dashboard.example.com
         http:
           paths:
           - path: /
             pathType: Prefix
             backend:
               service:
                 name: kubernetes-dashboard
                 port:
                   number: 443
     ```

     سپس فایل را اعمال کنید:
     ```bash
     kubectl apply -f ingress.yaml
     ```

     برای استفاده از HTTPS، باید گواهینامه SSL را با ابزارهایی مثل `cert-manager` تنظیم کنید.

---

### **مرحله ۳: مدیریت KubeVirt از طریق داشبورد**
KubeVirt به شما امکان می‌دهد ماشین‌های مجازی (VM) را در کنار کانتینرها در کلاستر Kubernetes مدیریت کنید. برای مدیریت KubeVirt از داشبورد:

1. **اطمینان از نصب KubeVirt**:
   اگر KubeVirt نصب نشده، آن را با دستور زیر نصب کنید:
   ```bash
   kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v1.0.0/kubevirt-operator.yaml
   kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/v1.0.0/kubevirt-cr.yaml
   ```
   نسخه را با آخرین نسخه موجود در مخزن KubeVirt جایگزین کنید.

2. **دسترسی به منابع KubeVirt در داشبورد**:
   پس از نصب KubeVirt، منابع آن (مانند `VirtualMachine` و `VirtualMachineInstance`) در داشبورد قابل مشاهده خواهند بود. در داشبورد:
   - به بخش **Workloads** یا **Custom Resources** بروید.
   - منابع KubeVirt مانند ماشین‌های مجازی، دیسک‌ها و تنظیمات شبکه را مشاهده و مدیریت کنید.

3. **ایجاد و مدیریت ماشین‌های مجازی**:
   برای ایجاد یک ماشین مجازی، می‌توانید از ویرایشگر YAML در داشبورد استفاده کنید. یک نمونه فایل YAML برای یک ماشین مجازی ساده:

   ```yaml
   apiVersion: kubevirt.io/v1
   kind: VirtualMachine
   metadata:
     name: example-vm
   spec:
     running: true
     template:
       metadata:
         labels:
           kubevirt.io/vm: example-vm
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
             image: quay.io/kubevirt/cirros-container-disk-demo
   ```

   این فایل را در داشبورد (بخش **Create** → **YAML**) وارد کرده و اعمال کنید.

---

### **مرحله ۴: نکات امنیتی و بهترین روش‌ها**
1. **محدود کردن دسترسی**:
   - از نقش `cluster-admin` برای حساب‌های خدماتی با احتیاط استفاده کنید. در صورت امکان، نقش‌های محدودتر (RBAC) تعریف کنید.
   - از HTTPS و Ingress برای دسترسی امن استفاده کنید.
   - اگر از NodePort استفاده می‌کنید، فایروال سرور را برای محدود کردن دسترسی به IPهای خاص تنظیم کنید.

2. **مانیتورینگ و عیب‌یابی**:
   - در صورت بروز مشکل (مثلاً عدم نمایش منابع KubeVirt)، لاگ‌های پادهای داشبورد را بررسی کنید:
     ```bash
     kubectl logs -n kubernetes-dashboard <dashboard-pod-name>
     ```
   - اطمینان حاصل کنید که APIهای KubeVirt در کلاستر فعال هستند.

3. **به‌روزرسانی و نگهداری**:
   - داشبورد و KubeVirt را به‌روز نگه دارید تا از ویژگی‌های جدید و رفع باگ‌ها بهره‌مند شوید.
   - برای به‌روزرسانی داشبورد، فایل YAML جدید را از مخزن رسمی اعمال کنید.

---

### **مرحله ۵: استفاده از داشبورد برای مدیریت**
پس از ورود به داشبورد:
- **نمای کلی**: اطلاعات کلی کلاستر مانند نودها، namespaces، و منابع را مشاهده کنید.
- **مدیریت منابع KubeVirt**: ماشین‌های مجازی، دیسک‌ها، و تنظیمات شبکه را ایجاد، ویرایش یا حذف کنید.
- **عیب‌یابی**: خطاها و وضعیت منابع را به صورت بصری بررسی کنید.
- **اسکریپت‌های YAML**: برای ایجاد منابع جدید یا تغییر تنظیمات از ویرایشگر YAML استفاده کنید.

---

### **منابع**
- مستندات رسمی داشبورد Kubernetes: [https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)


