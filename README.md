
# SystemdAutoRestart

A Bash utility to automate restarting systemd services at specific times or intervals with a user-friendly interface.

---

## Overview

SystemdAutoRestart is a Bash script designed to simplify the process of configuring automatic restarts for systemd services on Linux systems. With an intuitive interface, it allows users to schedule restarts either at a specific time daily or at regular intervals (e.g., every X hours). The script also provides functionality to remove existing auto-restart configurations, making it a versatile tool for system administrators.

---

## Features

- Automated Service Restarts: Configure systemd services to restart automatically at a specified time (e.g., 03:00 daily) or at regular intervals (e.g., every 8 hours).
- User-Friendly Interface: Clear prompts and colorful output inspired by an Otaku-friendly theme.
- Configuration Removal: Easily remove auto-restart configurations, including associated timers, services, and scripts.
- Error Handling: Robust validation for service names, time formats, and intervals to prevent misconfigurations.
- Systemd Integration: Creates systemd timers and services for reliable and efficient scheduling.

---

## Requirements

- Linux system with systemd installed
- Bash version 4.x or higher
- Root privileges (`sudo`) for execution
- Basic knowledge of systemd service names (e.g., `nginx.service`, `x-ui.service`)

---

## Installation

### Method 1: Clone the repository (Manual)

```bash
git clone https://github.com/KanekiDevPro/Auto-Restart.git
cd Auto-Restart
chmod +x AutoRestart.sh
sudo ./AutoRestart.sh
```

---

### Method 2: Run directly with curl and bash (Quick)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/KanekiDevPro/Auto-Restart/main/beta.sh)
```

> **Note:** This method requires `sudo` because the script needs root privileges to manage systemd services.

---

## Usage

Run the script with root privileges. The main menu offers:

1. **Configure Auto Restart for a Systemd Service:**  
   - Enter the exact service name (e.g., `nginx.service`).  
   - Choose to restart at a specific time daily or at regular intervals.  
   - The script creates systemd timer, service, and restart script in `/usr/local/bin`.

2. **Remove Auto Restart Configuration:**  
   - Enter the service name to delete its auto-restart setup (timer, service, script).

3. **Exit:** Close the script.

---

## Examples

- To configure `nginx.service` to restart daily at 03:00:  
  Run the script, select option 1, enter `nginx.service`, choose daily time, and enter `03:00`.

- To remove the configuration:  
  Run the script, select option 2, and enter the service name.

---

## Finding Service Names

You can list available systemd services by running:

```bash
systemctl list-units --type=service | grep .service
```

---

## Troubleshooting

- **"Service does not exist" error:** Verify the service name is correct using the command above.
- **Permission errors:** Make sure to run the script with `sudo`.
- **Timer not starting:** Check status with:

```bash
systemctl status restart-<service-name>.timer
```

---

## Contributing

Contributions are welcome! Please:

- Fork the repository.
- Create a new branch (`git checkout -b feature/your-feature`).
- Commit your changes (`git commit -m "Add your feature"`).
- Push to the branch (`git push origin feature/your-feature`).
- Open a pull request.

---

## License

This project is licensed under the MIT License.
