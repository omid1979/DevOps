برای اتوماسیون‌سازی آماده‌سازی سرورها با استفاده از Ansible، یک ساختار ماژولار و سازمان‌یافته ایجاد می‌کنیم که بر اساس سیستم‌عامل (Debian، Ubuntu و در آینده Alpine) دسته‌بندی شده و وظایف مختلف (پیکربندی سرور، نصب پکیج‌ها، تعریف کاربران، پیکربندی شبکه و هاردنینگ) را به‌صورت جداگانه مدیریت کند. هر فرآیند در یک فایل مانیفست (playbook) جداگانه تعریف می‌شود و یک فایل مانیفست اصلی تمام این فایل‌ها را فراخوانی می‌کند. این ساختار امکان مقیاس‌پذیری و نگهداری آسان را فراهم می‌کند.

### ساختار پروژه
ساختار پیشنهادی دایرکتوری به این صورت خواهد بود:

```
ansible_server_setup/
├── group_vars/
│   ├── debian.yml
│   ├── ubuntu.yml
│   └── alpine.yml
├── playbooks/
│   ├── main.yml
│   ├── package_install.yml
│   ├── user_setup.yml
│   ├── network_setup.yml
│   └── server_hardening.yml
├── inventory/
│   └── hosts.yml
└── roles/
    ├── common/
    │   └── tasks/
    │       ├── main.yml
    │       ├── package_install.yml
    │       ├── user_setup.yml
    │       ├── network_setup.yml
    │       └── server_hardening.yml
    ├── debian/
    │   └── tasks/
    │       ├── main.yml
    │       ├── package_install.yml
    │       ├── user_setup.yml
    │       ├── network_setup.yml
    │       └── server_hardening.yml
    ├── ubuntu/
    │   └── tasks/
    │       ├── main.yml
    │       ├── package_install.yml
    │       ├── user_setup.yml
    │       ├── network_setup.yml
    │       └── server_hardening.yml
    └── alpine/
        └── tasks/
            ├── main.yml
            ├── package_install.yml
            ├── user_setup.yml
            ├── network_setup.yml
            └── server_hardening.yml
```

### توضیحات ساختار
- **group_vars/**: متغیرهای خاص هر سیستم‌عامل (Debian، Ubuntu، Alpine) در فایل‌های جداگانه تعریف می‌شوند.
- **playbooks/**: شامل فایل‌های playbook برای هر وظیفه و یک playbook اصلی (main.yml) که وظایف را فراخوانی می‌کند.
- **inventory/hosts.yml**: فایل inventory که سرورها را بر اساس سیستم‌عامل گروه‌بندی می‌کند.
- **roles/**: نقش‌ها (roles) برای هر سیستم‌عامل به‌صورت جداگانه تعریف شده‌اند تا وظایف خاص هر سیستم‌عامل را مدیریت کنند. نقش `common` برای وظایف مشترک بین سیستم‌عامل‌ها استفاده می‌شود.

### فایل‌های مانیفست (Playbooks)

#### 1. فایل Inventory (hosts.yml)
این فایل سرورها را بر اساس سیستم‌عامل گروه‌بندی می‌کند.

```yaml
all:
  hosts:
    server1:
      ansible_host: 192.168.1.10
      ansible_user: admin
    server2:
      ansible_host: 192.168.1.11
      ansible_user: admin
  children:
    debian:
      hosts:
        server1:
    ubuntu:
      hosts:
        server2:
    alpine:
      hosts:
        # سرورهای Alpine در آینده اضافه می‌شوند
```

#### 2. متغیرهای گروه (group_vars)
متغیرهای خاص هر سیستم‌عامل برای سفارشی‌سازی وظایف.

```yaml
---
# متغیرهای خاص Debian
packages:
  - vim
  - curl
  - htop
users:
  - name: appuser
    password: "$6$randomsalt$hashedpassword"  # رمز هش‌شده
    groups: sudo
network_interface: eth0
ssh_port: 22
```

```yaml
---
# متغیرهای خاص Ubuntu
packages:
  - vim
  - curl
  - htop
users:
  - name: appuser
    password: "$6$randomsalt$hashedpassword"  # رمز هش‌شده
    groups: sudo
network_interface: eth0
ssh_port: 22
```

```yaml
---
# متغیرهای خاص Alpine (برای آینده)
packages:
  - vim
  - curl
users:
  - name: appuser
    password: "$6$randomsalt$hashedpassword"  # رمز هش‌شده
    groups: wheel
network_interface: eth0
ssh_port: 22
```

#### 3. فایل اصلی Playbook (main.yml)
این فایل وظایف را برای گروه‌های مختلف فراخوانی می‌کند.

```yaml
---
- name: Setup Debian servers
  hosts: debian
  become: yes
  roles:
    - debian

- name: Setup Ubuntu servers
  hosts: ubuntu
  become: yes
  roles:
    - ubuntu

- name: Setup Alpine servers
  hosts: alpine
  become: yes
  roles:
    - alpine
```

#### 4. نقش‌ها (Roles)
هر نقش شامل وظایف خاص برای هر سیستم‌عامل است. برای نمونه، نقش `debian` را نشان می‌دهیم.

##### نقش Debian
```yaml
---
- name: Include package installation tasks
  include_tasks: package_install.yml

- name: Include user setup tasks
  include_tasks: user_setup.yml

- name: Include network setup tasks
  include_tasks: network_setup.yml

- name: Include server hardening tasks
  include_tasks: server_hardening.yml
```

```yaml
---
- name: Update apt cache
  apt:
    update_cache: yes
  when: ansible_os_family == "Debian"

- name: Install required packages
  apt:
    name: "{{ packages }}"
    state: present
  when: ansible_os_family == "Debian"
```

```yaml
---
- name: Create users
  user:
    name: "{{ item.name }}"
    password: "{{ item.password }}"
    groups: "{{ item.groups }}"
    state: present
  loop: "{{ users }}"
  when: ansible_os_family == "Debian"
```

```yaml
---
- name: Configure network interface
  template:
    src: interfaces.j2
    dest: /etc/network/interfaces
    mode: '0644'
  when: ansible_os_family == "Debian"
  notify: restart networking
```

```yaml
---
- name: Disable root login via SSH
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^PermitRootLogin'
    line: 'PermitRootLogin no'
  when: ansible_os_family == "Debian"
  notify: restart sshd

- name: Set SSH port
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^Port'
    line: 'Port {{ ssh_port }}'
  when: ansible_os_family == "Debian"
  notify: restart sshd
```

##### نقش Ubuntu
مشابه نقش Debian، اما با تغییرات خاص Ubuntu (مانند استفاده از `ufw` برای فایروال).

```yaml
---
- name: Include package installation tasks
  include_tasks: package_install.yml

- name: Include user setup tasks
  include_tasks: user_setup.yml

- name: Include network setup tasks
  include_tasks: network_setup.yml

- name: Include server hardening tasks
  include_tasks: server_hardening.yml
```

```yaml
---
- name: Update apt cache
  apt:
    update_cache: yes
  when: ansible_os_family == "Debian"

- name: Install required packages
  apt:
    name: "{{ packages }}"
    state: present
  when: ansible_os_family == "Debian"
```

```yaml
---
- name: Create users
  user:
    name: "{{ item.name }}"
    password: "{{ item.password }}"
    groups: "{{ item.groups }}"
    state: present
  loop: "{{ users }}"
  when: ansible_os_family == "Debian"
```

```yaml
---
- name: Configure network interface
  template:
    src: netplan.j2
    dest: /etc/netplan/01-netcfg.yaml
    mode: '0644'
  when: ansible_os_family == "Debian"
  notify: apply netplan
```

```yaml
---
- name: Enable UFW
  ufw:
    state: enabled
    policy: deny
  when: ansible_os_family == "Debian"

- name: Allow SSH on custom port
  ufw:
    rule: allow
    port: "{{ ssh_port }}"
    proto: tcp
  when: ansible_os_family == "Debian"
```

##### نقش Alpine
برای Alpine، از `apk` برای مدیریت پکیج‌ها و ابزارهای خاص مانند `doas` به‌جای `sudo` استفاده می‌شود.

```yaml
---
- name: Include package installation tasks
  include_tasks: package_install.yml

- name: Include user setup tasks
  include_tasks: user_setup.yml

- name: Include network setup tasks
  include_tasks: network_setup.yml

- name: Include server hardening tasks
  include_tasks: server_hardening.yml
```

```yaml
---
- name: Update apk cache
  command: apk update
  when: ansible_os_family == "Alpine"

- name: Install required packages
  apk:
    name: "{{ packages }}"
    state: present
  when: ansible_os_family == "Alpine"
```

```yaml
---
- name: Create users
  user:
    name: "{{ item.name }}"
    password: "{{ item.password }}"
    groups: "{{ item.groups }}"
    state: present
  loop: "{{ users }}"
  when: ansible_os_family == "Alpine"
```

```yaml
---
- name: Configure network interface
  template:
    src: network.j2
    dest: /etc/network/interfaces
    mode: '0644'
  when: ansible_os_family == "Alpine"
  notify: restart networking
```

```yaml
---
- name: Disable root login via SSH
  lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^PermitRootLogin'
    line: 'PermitRootLogin no'
  when: ansible_os_family == "Alpine"
  notify: restart sshd
```

#### 5. Handlers
برای مدیریت سرویس‌ها (مانند ری‌استارت شبکه یا SSH) از handlers استفاده می‌کنیم.

```yaml
---
- name: restart networking
  service:
    name: networking
    state: restarted

- name: restart sshd
  service:
    name: sshd
    state: restarted
```

<xaiArtifact artifact_id="b32f1b81-72d0-4456-a4b7-2ed476b66e62" artifact_version_id="024aa073-81b2-4e6b-b62c-87669c95999f" title="ubuntu/handlers/main.yml" contentType="text/yaml">
---
- name: apply netplan
  command: netplan apply

- name: restart sshd
  service:
    name: sshd
    state: restarted
</xaiArtifact>

```yaml
---
- name: restart networking
  service:
    name: networking
    state: restarted

- name: restart sshd
  service:
    name: sshd
    state: restarted
```

### نحوه اجرا
1. فایل‌های بالا را در ساختار دایرکتوری مناسب ذخیره کنید.
2. اطمینان حاصل کنید که Ansible روی سیستم شما نصب است.
3. فایل inventory را با آدرس‌های واقعی سرورها به‌روزرسانی کنید.
4. دستور زیر را اجرا کنید:
   ```bash
   ansible-playbook -i inventory/hosts.yml playbooks/main.yml
   ```

### نکات اضافی
- **رمزهای هش‌شده**: برای امنیت، رمزهای کاربران را با ابزارهایی مانند `openssl passwd -6` هش کنید و در فایل‌های `group_vars` قرار دهید.
- **قالب‌های شبکه**: فایل‌های قالب (مانند `interfaces.j2` یا `netplan.j2`) باید در دایرکتوری `templates` هر نقش ایجاد شوند.
- **هاردنینگ پیشرفته**: برای هاردنینگ می‌توانید ماژول‌های اضافی مانند `ansible-hardening` را ادغام کنید.
- **گسترش‌پذیری**: برای اضافه کردن Alpine یا سیستم‌عامل‌های دیگر، کافی است نقش و متغیرهای مربوطه را اضافه کنید.

این ساختار منعطف و قابل‌توسعه است و امکان مدیریت سرورهای مختلف را به‌صورت خودکار فراهم می‌کند.

