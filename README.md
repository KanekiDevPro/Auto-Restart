SystemdAutoRestart
A Bash utility to automate restarting systemd services at specific times or intervals with a user-friendly interface.
Overview
SystemdAutoRestart is a Bash script designed to simplify the process of configuring automatic restarts for systemd services on Linux systems. With an intuitive interface, it allows users to schedule restarts either at a specific time daily or at regular intervals (e.g., every X hours). The script also provides functionality to remove existing auto-restart configurations, making it a versatile tool for system administrators.
Features

Automated Service Restarts: Configure systemd services to restart automatically at a specified time (e.g., 03:00 daily) or at regular intervals (e.g., every 8 hours).
User-Friendly Interface: Clear prompts and colorful output inspired by an Otaku-friendly theme.
Configuration Removal: Easily remove auto-restart configurations, including associated timers, services, and scripts.
Error Handling: Robust validation for service names, time formats, and intervals to prevent misconfigurations.
Systemd Integration: Creates systemd timers and services for reliable and efficient scheduling.

Requirements

Linux system with systemd installed
Bash version 4.x or higher
Root privileges (sudo) for execution
Basic knowledge of systemd service names (e.g., nginx.service, x-ui.service)

Installation

Clone the Repository:
git clone https://github.com/YourUsername/SystemdAutoRestart.git
cd SystemdAutoRestart


Set Execute Permissions:
chmod +x setup-auto-restart.sh



Usage
Run the script with root privileges:
sudo ./setup-auto-restart.sh

Main Menu Options

Configure Auto Restart for Systemd Service:

Enter the exact service name (e.g., nginx.service).
Choose to restart at a specific time daily (e.g., 03:00) or at regular intervals (e.g., every 8 hours).
The script creates a systemd timer, service, and a restart script in /usr/local/bin.


Remove Auto Restart Configuration:

Enter the service name to remove its auto-restart configuration.
The script deletes the associated timer, service, and script files.


Exit: Closes the script.


Example
To configure nginx.service to restart daily at 03:00:

Run sudo ./setup-auto-restart.sh.
Select option 1.
Enter nginx.service as the service name.
Choose option 1 (specific time) and enter 03:00.
Optionally test the restart immediately.

To remove the configuration:

Run sudo ./setup-auto-restart.sh.
Select option 2.
Enter nginx.service to delete the associated files.

Finding Service Names
To list available systemd services:
systemctl list-units --type=service | grep .service

Troubleshooting

Script fails with "Service does not exist":Ensure the service name is correct. Use systemctl list-units --type=service to verify.
Permission errors:Run the script with sudo.
Timer not starting:Check timer status with:systemctl status restart-<service-name>.timer



Contributing
Contributions are welcome! Please:

Fork the repository.
Create a new branch (git checkout -b feature/your-feature).
Commit your changes (git commit -m "Add your feature").
Push to the branch (git push origin feature/your-feature).
Open a pull request.

License
This project is licensed under the MIT License.
Contact
For issues or suggestions, open an issue on GitHub or contact [YourUsername] at [your-email@example.com].
