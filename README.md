SystemdAutoRestart

Automate the automatic restart of systemd services on Linux with a simple, intuitive Bash utility.

🌟 Key Features

Scheduled Restarts: Restart any systemd service at a fixed time daily (e.g., 03:00) or at regular intervals (e.g., every 8 hours).

User-Friendly Interface: Interactive prompts with clear instructions and colorized output for ease of use.

One-Command Setup: Quickly configure auto-restart in seconds—no manual file edits required.

Clean Removal: Remove existing auto-restart configurations effortlessly via the script.

Robust Validation: Checks service names, time formats, and intervals to prevent errors.

Systemd Integration: Leverages native systemd timers and service units for reliable scheduling.

📋 Requirements

OS: Any Linux distribution with systemd

Shell: Bash v4.x or higher

Permissions: Root access (sudo) to manage systemd units

🚀 Installation

Install in one step with root privileges:

bash <(curl -fsSL https://raw.githubusercontent.com/KanekiDevPro/Auto-Restart/main/beta.sh) --install

A symlink will be created at /usr/local/bin/systemd-autorestart for easy access.

🎛️ Usage

Run the command with sudo:

systemd-autorestart

Configure Auto-Restart

Service: Enter the full name (e.g., nginx.service).

Mode:

Daily: Set a specific time (HH:MM) for a once-a-day restart.

Interval: Set an hourly interval (X hours).

Remove Configuration

Select the service name to delete its timer, unit, and cleanup script.

Exit

Close the utility.

🔍 Examples

Restart nginx.service daily at 03:00

$ systemd-autorestart
(1) Configure  (2) Remove  (3) Exit
Select: 1
Service name: nginx.service
Mode: Daily
Time [HH:MM]: 03:00
✅ Auto-restart configured for nginx.service at 03:00 daily.

Restart x-ui.service every 8 hours

$ sudo systemd-autorestart
Select: 1
Service name: x-ui.service
Mode: Interval
Interval [hours]: 8
✅ Auto-restart configured every 8 hours.

🔧 Manage Configurations

List all active auto-restart timers:

systemctl list-timers --all | grep restart-.*\.timer

Check the status of a specific timer:

systemctl status restart-<service-name>.timer

🛠 Troubleshooting

Invalid Service: Ensure correct service name via:

systemctl list-units --type=service --no-pager

Permission Denied: Use sudo or run as root.

Timer Inactive: Start it manually:

sudo systemctl enable --now restart-<service-name>.timer

🤝 Contributing

Fork the repo

Create a feature branch (git checkout -b feature/your-feature)

Commit changes (git commit -m "Add feature")

Push (git push origin feature/your-feature)

Open a Pull Request

📄 License

Released under the MIT License.
