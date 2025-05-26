برای ساخت یک سیستم عامل اختصاصی مبتنی بر دبیان که به عنوان روتر کار کند، بدون محیط گرافیکی و با پکیج‌های مورد نظر شما، می‌توانیم از ابزارهای **debootstrap** و **live-build** استفاده کنیم، اما با تنظیماتی که سیستم را بهینه، سبک و مناسب برای کارکرد روتر کند. همچنین، فایل‌سیستم اصلی به صورت فقط خواندنی (Read-Only) تنظیم می‌شود، مسیر `/etc` جداگانه خواهد بود، امکان به‌روزرسانی فراهم می‌شود، و راهکارهایی برای بکاپ و ریست فکتوری پیاده‌سازی خواهد شد.

### ویژگی‌های سیستم
- **بدون محیط گرافیکی**: فقط خط فرمان (CLI) برای کاهش مصرف منابع.
- **فایل‌سیستم Read-Only**: برای جلوگیری از خرابی سیستم.
- **پشتیبانی از به‌روزرسانی**: با جدا کردن `/etc` و استفاده از ریپوزیتوری شخصی.
- **بکاپ و ریست فکتوری**: با استفاده از `rsync` و اسکریپت‌های سفارشی.
- **پکیج‌های مورد نظر**: شامل ابزارهای شبکه، امنیت، VPN، مانیتورینگ و پنل‌های مدیریتی.

### مراحل ساخت سیستم عامل
#### 1. آماده‌سازی محیط
- یک سیستم دبیان یا اوبونتو نصب کنید (ترجیحاً دبیان Stable).
- پکیج‌های مورد نیاز برای ساخت را نصب کنید:
  ```bash
  sudo apt update
  sudo apt install debootstrap live-build git reprepro
  ```

#### 2. ایجاد سیستم فایل پایه با debootstrap
- یک دایرکتوری برای سیستم فایل پایه ایجاد کنید:
  ```bash
  mkdir my-router-os
  sudo debootstrap --arch=amd64 stable my-router-os http://deb.debian.org/debian/
  ```
- وارد محیط chroot شوید:
  ```bash
  sudo chroot my-router-os
  ```

#### 3. نصب پکیج‌های مورد نظر
- پکیج‌های درخواستی شما را نصب کنید:
  ```bash
  apt update
  apt install iptables iproute2 tc traffic-control wondershaper vlan dnsmasq net-snmp snort suricata clamav squid squidguard dansguardian fail2ban rsync rsyslog wireguard strongswan openvpn easy-rsa nginx tcpdump nmap ntpsec keepalived pacemaker corosync webmin ajenti cockpit cloudpanel gnupanel
  ```
- نکته: برخی پکیج‌ها (مانند `wondershaper`, `cloudpanel`, `gnupanel`) ممکن است به صورت پیش‌فرض در مخازن دبیان موجود نباشند. برای این موارد، باید مخازن اضافی یا نصب دستی را تنظیم کنید. به عنوان مثال:
  - برای `wondershaper`:
    ```bash
    git clone https://github.com/magnific0/wondershaper.git
    cd wondershaper
    make install
    ```
  - برای `cloudpanel` یا `gnupanel`، به مستندات رسمی آن‌ها مراجعه کنید و بسته‌های `.deb` را به صورت دستی به ریپوزیتوری خود اضافه کنید.

#### 4. تنظیم فایل‌سیستم فقط خواندنی (Read-Only)
برای اطمینان از اینکه فایل‌سیستم اصلی فقط خواندنی باشد و `/etc` جداگانه باشد:
- فایل `/etc/fstab` را تنظیم کنید تا فایل‌سیستم اصلی (root) فقط خواندنی باشد و `/etc` روی یک پارتیشن قابل نوشتن باشد:

# /etc/fstab: static file system information.
proc            /proc           proc    defaults        0       0
/dev/sda1       /               ext4    ro,errors=remount-ro 0       1
/dev/sda2       /etc            ext4    rw,defaults     0       2
/dev/sda3       /var            ext4    rw,defaults     0       2
tmpfs           /tmp            tmpfs   rw,nosuid,nodev 0       0

- پارتیشن `/etc` و `/var` را روی دیسک جداگانه یا پارتیشن‌های قابل نوشتن تنظیم کنید.
- برای فعال کردن حالت فقط خواندنی، بعد از بوت، از اسکریپت زیر استفاده کنید:
```x-shellscript
#!/bin/bash
mount -o remount,ro /
echo "Root filesystem is now read-only"
```
- این اسکریپت را به `/etc/rc.local` یا یک سرویس systemd اضافه کنید تا در زمان بوت اجرا شود:
  ```bash
  chmod +x /make-readonly.sh
  ```

#### 5. ایجاد ریپوزیتوری شخصی برای به‌روزرسانی
- نصب و تنظیم `reprepro` برای ریپوزیتوری:
  ```bash
  mkdir -p ~/my-repo/conf
  cd ~/my-repo/conf
  ```
- فایل تنظیمات ریپوزیتوری:

Origin: MyRouterOS
Label: MyRouterOS Repository
Suite: stable
Codename: myrouteros
Architectures: amd64
Components: main
Description: My Custom Router OS Repository

- بسته‌های سفارشی را اضافه کنید:
  ```bash
  reprepro -b ~/my-repo includedeb myrouteros /path/to/your/package.deb
  ```
- ریپوزیتوری را روی سرور وب (مثل nginx) میزبانی کنید:
  ```bash
  sudo apt install nginx
  cp -r ~/my-repo /var/www/html/
  ```
- در سیستم عامل، ریپوزیتوری را به `/etc/apt/sources.list` اضافه کنید:
  ```bash
  echo "deb http://your-server/my-repo myrouteros main" >> /etc/apt/sources.list
  ```

#### 6. تنظیم بکاپ با rsync
- یک اسکریپت برای بکاپ‌گیری از `/etc` و `/var` ایجاد کنید:
```x-shellscript
#!/bin/bash
BACKUP_DIR="/backup"
TIMESTAMP=$(date +%F_%H-%M-%S)
rsync -av /etc /backup/etc-$TIMESTAMP
rsync -av /var /backup/var-$TIMESTAMP
echo "Backup completed: etc-$TIMESTAMP, var-$TIMESTAMP"
```
- دایرکتوری بکاپ را تنظیم کنید:
  ```bash
  mkdir /backup
  chmod +x /backup.sh
  ```
- برای بکاپ دوره‌ای، یک کار cron اضافه کنید:
  ```bash
  crontab -e
  ```
  و خط زیر را اضافه کنید تا هر روز بکاپ گرفته شود:
  ```bash
  0 2 * * * /backup.sh
  ```

#### 7. تنظیم ریست فکتوری
- یک اسکریپت برای ریست فکتوری ایجاد کنید که تنظیمات پیش‌فرض را بازیابی کند:
```x-shellscript
#!/bin/bash
# Restore default configurations
rsync -av /etc.default/ /etc/
rsync -av /var.default/ /var/
echo "Factory reset completed. Rebooting..."
reboot
```
- دایرکتوری‌های پیش‌فرض را ایجاد کنید:
  ```bash
  mkdir /etc.default /var.default
  rsync -av /etc/ /etc.default/
  rsync -av /var/ /var.default/
  chmod +x /factory-reset.sh
  ```
- برای دسترسی آسان، می‌توانید یک دستور یا دکمه (در صورت استفاده از پنل‌های مدیریتی مثل webmin) برای اجرای این اسکریپت تنظیم کنید.

#### 8. ساخت ایمیج با live-build
- پروژه live-build را پیکربندی کنید:
  ```bash
  lb config --distribution stable --architecture amd64 --bootappend-live "boot=live"
  ```
- پکیج‌های مورد نظر را در `config/package-lists/my.list.chroot` اضافه کنید:

iptables
iproute2
tc
wondershaper
vlan
dnsmasq
net-snmp
snort
suricata
clamav
squid
squidguard
dansguardian
fail2ban
rsync
rsyslog
wireguard
strongswan
openvpn
easy-rsa
nginx
tcpdump
nmap
ntpsec
keepalived
pacemaker
corosync
webmin
ajenti
cockpit
cloudpanel
gnupanel

- منوی GRUB را برای بوت سفارشی کنید:

set timeout=5
set default=0

menuentry "MyRouterOS Live" {
    linux /vmlinuz boot=live
    initrd /initrd.img
}
menuentry "MyRouterOS Install" {
    linux /vmlinuz boot=install
    initrd /initrd.img
}

- ایمیج را بسازید:
  ```bash
  sudo lb build
  ```

#### 9. تست و توزیع
- ایمیج را با QEMU تست کنید:
  ```bash
  qemu-system-x86_64 -cdrom binary.iso
  ```
- ایمیج را روی USB یا دیسک رایت کنید:
  ```bash
  sudo dd if=binary.iso of=/dev/sdX bs=4M status=progress
  ```
- برای توزیع، ایمیج و ریپوزیتوری را روی سرور وب قرار دهید.

### نکات اضافی
- **بهینه‌سازی برای روتر**: پکیج‌های غیرضروری (مانند ابزارهای گرافیکی) را حذف کنید تا سیستم سبک‌تر شود.
- **امنیت**: فایل‌های پیکربندی VPN (مانند WireGuard و OpenVPN) را با کلیدهای امن تنظیم کنید. برای مثال، برای WireGuard:
  ```bash
  wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
  ```
- **پنل‌های مدیریتی**: Webmin و Cockpit گزینه‌های خوبی برای مدیریت از طریق مرورگر هستند. اطمینان حاصل کنید که پورت‌های آن‌ها (مثلاً 10000 برای Webmin) در فایروال باز باشند:
  ```bash
  iptables -A INPUT -p tcp --dport 10000 -j ACCEPT
  ```
- **مانیتورینگ**: از `net-snmp` و `tcpdump` برای مانیتورینگ شبکه استفاده کنید و خروجی را به syslog بفرستید:
  ```bash
  echo "*.* /var/log/syslog" >> /etc/rsyslog.conf
  ```

### نتیجه
این روش یک سیستم عامل سبک و اختصاصی مبتنی بر دبیان ایجاد می‌کند که:
- به عنوان روتر با پکیج‌های شبکه و امنیتی کار می‌کند.
- فایل‌سیستم فقط خواندنی دارد، با `/etc` جداگانه برای به‌روزرسانی.
- امکان بکاپ‌گیری با `rsync` و ریست فکتوری را فراهم می‌کند.
- از ریپوزیتوری شخصی برای به‌روزرسانی پشتیبانی می‌کند.

اگر نیاز به جزئیات بیشتر در مورد پیکربندی خاص هر پکیج (مثلاً Suricata یا WireGuard) یا عیب‌یابی دارید، اطلاع دهید!
