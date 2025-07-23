## SystemdAutoRestart

Automate the automatic restart of systemd services on Linux with a simple, intuitive Bash utility.

---

### 🌟 Key Features

- **Scheduled Restarts**: Restart any systemd service at a fixed time daily (e.g., 03:00) or at regular intervals (e.g., every 8 hours).
- **User-Friendly Interface**: Interactive prompts with clear instructions and colorized output for ease of use.
- **One-Command Setup**: Quickly configure auto-restart in seconds—no manual file edits required.
- **Clean Removal**: Remove existing auto-restart configurations effortlessly via the script.
- **Robust Validation**: Checks service names, time formats, and intervals to prevent errors.
- **Systemd Integration**: Leverages native systemd timers and service units for reliable scheduling.

---

### 📋 Requirements

- **OS**: Any Linux distribution with systemd
- **Shell**: Bash v4.x or higher
- **Permissions**: Root access (`sudo`) to manage systemd units

---

### 🚀 Installation

Install in one step with root privileges:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/KanekiDevPro/Auto-Restart/main/beta.sh) --install
```

> A symlink will be created at `/usr/local/bin/systemd-autorestart` for easy access.

---

### 🔍 Examples

- **Restart `nginx.service` daily at 03:00**

  ```bash
  $ systemd-autorestart
  (1) Configure  (2) Remove  (3) Exit
  Select: 1
  Service name: nginx.service
  Mode: Daily
  Time [HH:MM]: 03:00
  ✅ Auto-restart configured for nginx.service at 03:00 daily.
  ```

- **Restart `x-ui.service` every 8 hours**

  ```bash
  $ sudo systemd-autorestart
  Select: 1
  Service name: x-ui.service
  Mode: Interval
  Interval [hours]: 8
  ✅ Auto-restart configured every 8 hours.
  ```

---

### 🔧 Manage Configurations

List all active auto-restart timers:

```bash
systemctl list-timers --all | grep restart-.*\.timer
```

Check the status of a specific timer:

```bash
systemctl status restart-<service-name>.timer
```  

---

### 🛠 Troubleshooting

- **Invalid Service**: Ensure correct service name via:
  ```bash
  systemctl list-units --type=service --no-pager
  ```
- **Permission Denied**: Use `sudo` or run as root.
- **Timer Inactive**: Start it manually:
  ```bash
  sudo systemctl enable --now restart-<service-name>.timer
  ```

---

### 🤝 Contributing

1. Fork the repo  
2. Create a feature branch (`git checkout -b feature/your-feature`)  
3. Commit changes (`git commit -m "Add feature"`)  
4. Push (`git push origin feature/your-feature`)  
5. Open a Pull Request

---

### 📄 License

Released under the MIT License.
