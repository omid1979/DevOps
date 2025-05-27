برای اجرای **Ansible** و **Semaphore** به صورت یک استک داکری که با هم کار کنند، می‌تونید از **Docker Compose** استفاده کنید تا هر دو سرویس به صورت هماهنگ بالا بیاد و مدیریت بشن. Semaphore یک رابط کاربری وب برای اجرای playbook‌های Ansible ارائه می‌ده و معمولاً به یک دیتابیس (مثل MySQL یا PostgreSQL) نیاز داره. در ادامه، یه راهنمای قدم به قدم برای راه‌اندازی این استک با Docker Compose براتون توضیح می‌دم.

### پیش‌نیازها
1. **نصب Docker و Docker Compose**:
   - مطمئن بشید Docker و Docker Compose روی سیستم نصب هستن. می‌تونید با دستورات زیر نصب رو چک کنید:
     ```bash
     docker --version
     docker-compose --version
     ```
   - اگر نصب نیستن، طبق مستندات رسمی Docker نصبشون کنید.

2. **تصویر Ansible**:
   - شما قبلاً تصویر `ansible/ansible:ubuntu1604` رو دانلود کردید. این تصویر برای اجرای playbook‌ها استفاده می‌شه.

3. **تصویر Semaphore**:
   - از تصویر رسمی `semaphoreui/semaphore:latest` برای Semaphore استفاده می‌کنیم، چون نسخه به‌روزتریه و با دیتابیس‌های مختلف سازگاره.

4. **فایل‌های مورد نیاز**:
   - یه دایرکتوری برای پروژه (مثل `ansible-semaphore`) بسازید.
   - فایل‌های playbook، inventory و کلیدهای SSH رو آماده کنید.

### قدم ۱: تنظیم فایل Docker Compose
یه فایل به نام `docker-compose.yml` توی دایرکتوری پروژه بسازید و کد زیر رو توش قرار بدید. این فایل یه استک شامل Semaphore، دیتابیس (PostgreSQL) و یه سرویس برای اجرای Ansible تعریف می‌کنه:

```yaml
version: '3.8'
services:
  semaphore:
    image: semaphoreui/semaphore:latest
    container_name: semaphore
    ports:
      - "3000:3000"
    environment:
      - SEMAPHORE_DB_DIALECT=postgres
      - SEMAPHORE_DB_HOST=postgres
      - SEMAPHORE_DB_PORT=5432
      - SEMAPHORE_DB_USER=semaphore
      - SEMAPHORE_DB_PASS=strongpassword
      - SEMAPHORE_DB=semaphore
      - SEMAPHORE_PLAYBOOK_PATH=/tmp/semaphore
      - SEMAPHORE_ADMIN=admin
      - SEMAPHORE_ADMIN_PASSWORD=adminpassword
      - SEMAPHORE_ADMIN_NAME=Admin
      - SEMAPHORE_ADMIN_EMAIL=admin@localhost
      - SEMAPHORE_ACCESS_KEY_ENCRYPTION=5Hlv7RZ+yCKBqOWqZ5WLXlOqZjdJF4Zj4OK9dcOaOnU=
    volumes:
      - ./semaphore:/tmp/semaphore
      - ./ssh:/root/.ssh
    depends_on:
      - postgres
    networks:
      - sema-net
    restart: unless-stopped

  postgres:
    image: postgres:14
    container_name: postgres
    environment:
      - POSTGRES_USER=semaphore
      - POSTGRES_PASSWORD=strongpassword
      - POSTGRES_DB=semaphore
    volumes:
      - semaphore-postgres:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - sema-net
    restart: unless-stopped

  ansible:
    image: ansible/ansible:ubuntu1604
    container_name: ansible
    volumes:
      - ./playbooks:/ansible/playbooks
      - ./ssh:/root/.ssh
    networks:
      - sema-net
    command: tail -f /dev/null  # Keep container running
    restart: unless-stopped

networks:
  sema-net:
    driver: bridge

volumes:
  semaphore-postgres:
```

### توضیحات فایل Docker Compose
- **Semaphore**:
  - تصویر: `semaphoreui/semaphore:latest`
  - پورت: 3000 برای دسترسی به رابط وب
  - متغیرهای محیطی: تنظیمات دیتابیس، مسیر playbook‌ها و اطلاعات ادمین
  - volume: مسیر `/tmp/semaphore` برای ذخیره playbook‌ها و `/root/.ssh` برای کلیدهای SSH
  - وابستگی: به سرویس `postgres` وابسته است
- **PostgreSQL**:
  - تصویر: `postgres:14`
  - پورت: 5432
  - volume: برای ذخیره دیتابیس
  - متغیرهای محیطی: برای تنظیم نام کاربری، رمز و دیتابیس
- **Ansible**:
  - تصویر: `ansible/ansible:ubuntu1604`
  - volume: برای mount کردن playbook‌ها و کلیدهای SSH
  - دستور `tail -f /dev/null`: برای نگه داشتن کانتینر در حالت اجرا
- **شبکه**:
  - یه شبکه bridge به نام `sema-net` برای ارتباط بین سرویس‌ها
- **Volume**:
  - برای ذخیره دیتابیس PostgreSQL

### قدم ۲: آماده‌سازی فایل‌ها و کلیدهای SSH
1. **ساخت دایرکتوری‌ها**:
   ```bash
   mkdir -p ansible-semaphore/{playbooks,ssh,semaphore}
   cd ansible-semaphore
   ```
2. **کپی کلیدهای SSH**:
   کلیدهای SSH خودتون (مثل `id_rsa` و `id_rsa.pub`) رو توی دایرکتوری `./ssh` کپی کنید:
   ```bash
   cp ~/.ssh/id_rsa ./ssh/
   cp ~/.ssh/id_rsa.pub ./ssh/
   chmod 600 ./ssh/id_rsa
   ```
3. **ایجاد playbook نمونه**:
   یه فایل playbook نمونه (مثل `test.yml`) توی دایرکتوری `./playbooks` بسازید:
   ```yaml
   ---
   - name: Test playbook
     hosts: all
     gather_facts: yes
     tasks:
       - name: Display hostname
         debug:
           msg: "Hostname: {{ ansible_hostname }}"
   ```
4. **ایجاد inventory**:
   یه فایل inventory (مثل `inventory.ini`) توی دایرکتوری `./playbooks` بسازید:
   ```ini
   [web_servers]
   your_server_ip ansible_user=your_ssh_user
   ```

### قدم ۳: اجرای Docker Compose
توی دایرکتوری پروژه، دستور زیر رو اجرا کنید:
```bash
docker-compose up -d
```
این دستور کانتینرهای Semaphore، PostgreSQL و Ansible رو بالا میاره.

### قدم ۴: دسترسی به Semaphore
1. مرورگر رو باز کنید و به آدرس زیر برید:
   ```
   http://localhost:3000
   ```
2. با اطلاعات ادمین وارد بشید:
   - نام کاربری: `admin`
   - رمز: `adminpassword` (یا هر رمزی که توی فایل `docker-compose.yml` تنظیم کردید)

### قدم ۵: پیکربندی Semaphore
1. **ایجاد پروژه**:
   - توی رابط کاربری Semaphore، یه پروژه جدید بسازید و نامی براش انتخاب کنید.
2. **اضافه کردن Key Store**:
   - کلید SSH رو به Key Store اضافه کنید (مسیر: `/root/.ssh/id_rsa`).
   - اگر playbook نیاز به sudo داره، رمز sudo رو هم به Key Store اضافه کنید.
3. **اضافه کردن Repository**:
   - یه repository به مسیر `/tmp/semaphore` متصل کنید (محل ذخیره playbook‌ها).
4. **اضافه کردن Inventory**:
   - فایل inventory (مثل `/ansible/playbooks/inventory.ini`) رو به Semaphore معرفی کنید.
5. **ایجاد Task Template**:
   - یه template برای اجرای playbook بسازید و مسیر playbook (مثل `/tmp/semaphore/test.yml`) رو مشخص کنید.
6. **اجرای Task**:
   - از رابط کاربری، task رو اجرا کنید تا playbook روی سرورهای مشخص شده اجرا بشه.

### قدم ۶: اجرای مستقیم Ansible (اختیاری)
اگر بخواید playbook رو مستقیماً از کانتینر Ansible اجرا کنید:
```bash
docker exec -it ansible ansible-playbook /ansible/playbooks/test.yml -i /ansible/playbooks/inventory.ini
```

### نکات مهم
- **امنیت**: رمزهای قوی برای `SEMAPHORE_ADMIN_PASSWORD` و `SEMAPHORE_DB_PASS` تنظیم کنید. کلید `SEMAPHORE_ACCESS_KEY_ENCRYPTION` رو با دستور زیر بسازید:
  ```bash
  head -c32 /dev/urandom | base64
  ```
- **شبکه**: همه سرویس‌ها توی شبکه `sema-net` هستن، پس Semaphore می‌تونه به راحتی با دیتابیس و Ansible ارتباط برقرار کنه.
- **مدیریت کانتینرها**:
  - برای توقف: `docker-compose stop`
  - برای حذف: `docker-compose down`
  - برای مشاهده لاگ‌ها: `docker-compose logs`
- **تصاویر به‌روز**: تصویر `ansible/ansible:ubuntu1604` قدیمیه. اگر نیاز به نسخه جدیدتر Ansible دارید، می‌تونید از تصویرهایی مثل `ansible/ansible-runner` استفاده کنید.
- **منابع**: این راهنما با الهام از مستندات Semaphore و راهنمای وب موجود تنظیم شده.[](https://medium.com/%40obuyajohn54/automating-ansible-with-semaphore-in-docker-a-step-by-step-guide-ee4880898338)

### عیب‌یابی
- **دسترسی SSH**: مطمئن بشید کلیدهای SSH درست mount شدن و سرورهای مقصد توی `known_hosts` هستن.
- **ارتباط دیتابیس**: اگر Semaphore به دیتابیس وصل نشد، تنظیمات `SEMAPHORE_DB_*` رو چک کنید.
- **لاگ‌ها**: لاگ‌های Semaphore و Ansible رو با `docker logs semaphore` یا `docker logs ansible` بررسی کنید.


