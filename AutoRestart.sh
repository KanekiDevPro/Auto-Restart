```bash
#!/bin/bash

# Define colors - Otaku-friendly theme!
MAGENTA='\033[0;35m'  # Purple/Magenta for borders
CYAN='\033[0;36m'     # Cyan/Light Blue for text
RED='\033[0;31m'      # Red for error/warning
GREEN='\033[0;32m'    # Green for success
YELLOW='\033[0;33m'   # Yellow for warnings/tips
NC='\033[0m'          # No Color (reset)
BOLD='\033[1m'        # Bold text

# --- Check for root privileges ---
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}${BOLD}❌ This script must be run with root privileges (sudo).${NC}"
    echo -e "${CYAN}Please run the command as: ${BOLD}sudo ./AutoRestart.sh${NC}"
    exit 1
fi

# --- Function to display the main menu ---
display_main_menu() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    echo "   _         _            __           _             _   "
    echo "  /_\  _   _| |_ ___     /__\ ___  ___| |_ __ _ _ __| |_ "
    echo " //_\\| | | | __/ _ \\   / \\/// _ \\/ __| __/ _\` | '__| __|"
    echo "/  _  \\ |_| | || (_) | / _  \\  __/\\__ \\ || (_| | |  | |_ "
    echo "\\_/ \\_/\\__,_|\\__\\___/  \\/ \\_/\\___||___/\\__\\__,_|_|   \\__|"
    echo "                                                         "
    echo -e "${CYAN}GitHub: KanekiDevPro ${NC}"
    echo -e "${CYAN}Version: 1.0.0${NC}"
    echo -e "${MAGENTA}${BOLD}+-----------------------------------------------------------------------------+${NC}"
    echo -e "${CYAN}${BOLD}| PLEASE CHOOSE THE OPTION:                                                   |${NC}"
    echo -e "${MAGENTA}${BOLD}+-----------------------------------------------------------------------------+${NC}"
    echo -e "${CYAN}| 1 - Configure Auto Restart for Systemd Service                              |${NC}"
    echo -e "${CYAN}| 2 - Remove Auto Restart Configuration                                       |${NC}"
    echo -e "${CYAN}| 0 - Exit The Matrix                                                         |${NC}"
    echo -e "${MAGENTA}${BOLD}+-----------------------------------------------------------------------------+${NC}"
    echo -e "${CYAN}| Enter your choice: ${NC}\c"
}

# --- Function for the Auto Restart Systemd Service Setup ---
configure_auto_restart_service() {
    clear
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD} 🔁 Auto Restart Systemd Service Setup${NC}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}🔍 Tip: To find your service name, run:${NC}"
    echo -e "${CYAN}    systemctl list-units --type=service | grep .service${NC}"
    echo -e "${CYAN}Example: x-ui.service, nginx.service, etc.${NC}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    read -p "$(echo -e "${CYAN}📦 Enter the exact service name (e.g. x-ui.service): ${NC}")" SERVICE_NAME

    if [[ -z "$SERVICE_NAME" ]]; then
        echo -e "${RED}${BOLD}❌ Service name cannot be empty. Returning to main menu.${NC}"
        sleep 2
        return
    fi

    if ! systemctl list-unit-files --type=service --all | grep -q "^${SERVICE_NAME}\s"; then
        echo -e "${RED}${BOLD}❌ Error: Service '$SERVICE_NAME' does not exist on this system.${NC}"
        echo -e "${RED}Please verify the service name and try again.${NC}"
        sleep 3
        return
    fi

    BASE_NAME=$(echo "$SERVICE_NAME" | sed 's/\.service$//')

    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}⏱ How often do you want to restart?${NC}"
    echo -e "${CYAN}1) At a specific time every day (e.g. 03:00)${NC}"
    echo -e "${CYAN}2) Every X hours (e.g. every 8 hours)${NC}"
    read -p "$(echo -e "${CYAN}Choose option (1 or 2): ${NC}")" TIME_MODE

    if [[ "$TIME_MODE" == "1" ]]; then
        read -p "$(echo -e "${CYAN}🕒 Enter the time (24h format, e.g. 03:00): ${NC}")" TIME_VALUE
        if [[ -z "$TIME_VALUE" ]]; then
            echo -e "${RED}${BOLD}❌ Time cannot be empty. Returning to main menu.${NC}"
            sleep 2
            return
        fi
        if ! [[ "$TIME_VALUE" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
            echo -e "${RED}${BOLD}❌ Invalid time format (e.g., 03:00). Returning to main menu.${NC}"
            sleep 2
            return
        fi
        ONCALENDAR="*-*-* $TIME_VALUE:00"
    elif [[ "$TIME_MODE" == "2" ]]; then
        read -p "$(echo -e "${CYAN}🔁 Enter the interval in hours (e.g. 8): ${NC}")" TIME_VALUE
        if ! [[ "$TIME_VALUE" =~ ^[0-9]+$ ]] || (( TIME_VALUE == 0 )); then
            echo -e "${RED}${BOLD}❌ Interval must be a positive number. Returning to main menu.${NC}"
            sleep 2
            return
        fi
        ONCALENDAR="hourly"
        FIXED_INTERVAL="yes"
    else
        echo -e "${RED}${BOLD}❌ Invalid option. Returning to main menu.${NC}"
        sleep 2
        return
    fi

    SCRIPT_PATH="/usr/local/bin/restart-${BASE_NAME}.sh"
    echo -e "${CYAN}📁 Creating script: ${BOLD}$SCRIPT_PATH${NC}"
    cat <<EOF > "$SCRIPT_PATH"
#!/bin/bash
systemctl restart $SERVICE_NAME
EOF
    chmod +x "$SCRIPT_PATH"

    SERVICE_FILE="/etc/systemd/system/restart-${BASE_NAME}.service"
    echo -e "${CYAN}🛠 Creating systemd service: ${BOLD}$SERVICE_FILE${NC}"
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Auto Restart for $SERVICE_NAME

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF

    TIMER_FILE="/etc/systemd/system/restart-${BASE_NAME}.timer"
    echo -e "${CYAN}⏱ Creating systemd timer: ${BOLD}$TIMER_FILE${NC}"

    if [[ "$FIXED_INTERVAL" == "yes" ]]; then
        cat <<EOF > "$TIMER_FILE"
[Unit]
Description=Restart $SERVICE_NAME every ${TIME_VALUE} hours

[Timer]
OnBootSec=${TIME_VALUE}h
OnUnitActiveSec=${TIME_VALUE}h
Persistent=true

[Install]
WantedBy=timers.target
EOF
    else
        cat <<EOF > "$TIMER_FILE"
[Unit]
Description=Daily restart of $SERVICE_NAME at $TIME_VALUE

[Timer]
OnCalendar=$ONCALENDAR
Persistent=true

[Install]
WantedBy=timers.target
EOF
    fi

    echo -e "${CYAN}🚀 Enabling and starting timer...${NC}"
    systemctl daemon-reload
    systemctl enable --now "restart-${BASE_NAME}.echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}${BOLD}✅ Auto-restart configured for: ${SERVICE_NAME}${NC}"
    echo -e "${CYAN}🔁 Restart style: $([ "$FIXED_INTERVAL" == "yes" ] && echo "Every $TIME_VALUE hours" || echo "Daily at $TIME_VALUE")${NC}"
    echo -e "${CYAN}🔧 Timer status:${NC}"
    systemctl list-timers | grep "restart-${BASE_NAME}" || echo -e "${YELLOW}Warning: Timer not listed, check systemctl status restart-${BASE_NAME}.timer${NC}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    read -p "$(echo -e "${CYAN}⚙️ Do you want to test the restart now? (y/n): ${NC}")" do_test
    if [[ "$do_test" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Testing service restart for ${BOLD}$SERVICE_NAME${NC}..."
        systemctl start "$SERVICE_NAME" || {
            echo -e "${RED}${BOLD}❌ Failed to restart service. Check systemctl status $SERVICE_NAME for details.${NC}"
            sleep 3
        }
        echo -e "${CYAN}📄 Last 10 lines of logs from ${BOLD}$SERVICE_NAME${NC}:"
        journalctl -u "$SERVICE_NAME" -n 10 --no-pager
    else
        echo -e "${GREEN}🎉 Done! Your service will restart automatically as scheduled.${NC}"
    fi

    echo -e "${CYAN}Press any key to return to main menu...${NC}"
    read -n 1 -s
}

# --- Function to remove an existing Auto Restart Configuration ---
remove_auto_restart_configuration() {
    clear
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}${BOLD} 🗑️ Remove Auto Restart Configuration${NC}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo -e "${CYAN}💡 Timers configured by this script:${NC}"
    CONFIGURED_TIMERS=$(systemctl list-timers --no-pager | grep "restart-" | awk '{print $NF}' | sed 's/^restart-//; s/\.timer$//; s/$/\.service/' | sort -u)
    if [[ -z "$CONFIGURED_TIMERS" ]]; then
        echo -e "${YELLOW}  (No configured timers found.)${NC}"
    else
        echo -e "${CYAN}${BOLD}----------------------------------------${NC}"
        echo -e "${CONFIGURED_TIMERS}" | nl -w2 -s'. ' | sed 's/^/  /'
        echo -e "${CYAN}${BOLD}----------------------------------------${NC}"
    fi
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    read -p "$(echo -e "${CYAN}📦 Enter the exact service name that was configured (e.g. x-ui.service): ${NC}")" SERVICE_NAME

    if [[ -z "$SERVICE_NAME" ]]; then
        echo -e "${RED}${BOLD}❌ Service name cannot be empty. Returning to main menu.${NC}"
        sleep 2
        return
    fi

    BASE_NAME=$(echo "$SERVICE_NAME" | sed 's/\.service$//')
    TIMER_UNIT="restart-${BASE_NAME}.timer"
    SERVICE_UNIT="restart-${BASE_NAME}.service"
    SCRIPT_PATH="/usr/local/bin/restart-${BASE_NAME}.sh"
    TIMER_FILE="/etc/systemd/system/${TIMER_UNIT}"
    SERVICE_FILE="/etc/systemd/system/${SERVICE_UNIT}"

    if [[ ! -f "$TIMER_FILE" && ! -f "$SERVICE_FILE" && ! -f "$SCRIPT_PATH" ]]; then
        echo -e "${RED}${BOLD}❌ Error: No auto-restart configuration found for service '$SERVICE_NAME'.${NC}"
        echo -e "${RED}Please ensure the service name is correct and it was previously configured.${NC}"
        sleep 3
        return
    fi

    echo -e "${CYAN}Attempting to remove configuration for: ${BOLD}$SERVICE_NAME${NC}"

    if systemctl is-active --quiet "$TIMER_UNIT" || systemctl is-enabled --quiet "$TIMER_UNIT"; then
        echo -e "${CYAN}Stopping and disabling timer: ${BOLD}$TIMER_UNIT${NC}"
        systemctl stop "$TIMER_UNIT" || echo -e "${YELLOW}Warning: Failed to stop timer.${NC}"
        systemctl disable "$TIMER_UNIT" || echo -e "${YELLOW}Warning: Failed to disable timer.${NC}"
    else
        echo -e "${YELLOW}Warning: Timer '$TIMER_UNIT' not active or enabled. Proceeding with file deletion.${NC}"
    fi

    if [ -f "$TIMER_FILE" ]; then
        echo -e "${CYAN}Deleting timer file: ${BOLD}$TIMER_FILE${NC}"
        rm -f "$TIMER_FILE"
    else
        echo -e "${YELLOW}Warning: Timer file not found: ${BOLD}$TIMER_FILE${NC}"
    fi

    if [ -f "$SERVICE_FILE" ]; then
        echo -e "${CYAN}Deleting service file: ${BOLD}$SERVICE_FILE${NC}"
        rm -f "$SERVICE_FILE"
    else
        echo -e "${YELLOW}Warning: Service file not found: ${BOLD}$SERVICE_FILE${NC}"
    fi

    if [ -f "$SCRIPT_PATH" ]; then
        echo -e "${CYAN}Deleting script file: ${BOLD}$SCRIPT_PATH${NC}"
        rm -f "$SCRIPT_PATH"
    else
        echo -e "${YELLOW}Warning: Script file not found: ${BOLD}$SCRIPT_PATH${NC}"
    fi

    systemctl daemon-reload
    echo -e "${GREEN}${BOLD}✅ Removal process complete. Please verify using 'systemctl list-timers'.${NC}"
    echo -e "${CYAN}Press any key to return to main menu...${NC}"
    read -n 1 -s
}

# --- Main program loop ---
while true; do
    display_main_menu
    read -r choice

    case "$choice" in
        1)
            configure_auto_restart_service
            ;;
        2)
            remove_auto_restart_configuration
            ;;
        0)
            echo -e "${CYAN}Exiting The Matrix. See you soon!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}${BOLD}❌ Invalid choice. Please enter a valid option (0, 1, or 2).${NC}"
            sleep 2
            ;;
    esac
done
