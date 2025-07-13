#!/bin/bash

# --- Colors & Styles ---
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
BOLD='\033[1m'

VERSION="1.1.0"

# --- Logging helpers ---
log_error()   { echo -e "${RED}${BOLD}❌ $1${NC}"; }
log_success() { echo -e "${GREEN}${BOLD}✅ $1${NC}"; }
log_info()    { echo -e "${CYAN}$1${NC}"; }
log_warn()    { echo -e "${YELLOW}⚠️ $1${NC}"; }

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root."
    log_info "Run: ${BOLD}sudo $0${NC}"
    exit 1
fi

# --- Main Menu (ASCII/OTAKU BANNER STYLE) ---
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
    echo -e "${CYAN}Version: $VERSION${NC}"
    echo -e "${MAGENTA}${BOLD}+-----------------------------------------------------------------------------+${NC}"
    echo -e "${CYAN}${BOLD}| PLEASE CHOOSE AN OPTION:                                                    |${NC}"
    echo -e "${MAGENTA}${BOLD}+-----------------------------------------------------------------------------+${NC}"
    echo -e "${CYAN}| 1 - Configure Auto Restart for a Systemd Service                            |${NC}"
    echo -e "${CYAN}| 2 - Remove Auto Restart Configuration                                       |${NC}"
    echo -e "${CYAN}| 0 - Exit                                                                    |${NC}"
    echo -e "${MAGENTA}${BOLD}+-----------------------------------------------------------------------------+${NC}"
    echo -ne "${CYAN}| Enter your choice: ${NC}"
}

# --- Configure auto restart ---
configure_auto_restart_service() {
    clear
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD} 🔁 Auto Restart Systemd Service Setup${NC}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    log_info "Tip: To find your service name, run:"
    echo -e "${CYAN}  systemctl list-units --type=service | grep x${NC}"
    log_info "Example: x-ui.service, nginx.service, etc."
    echo

    read -p "$(echo -e "${CYAN}Enter the exact service name (e.g. x-ui.service): ${NC}")" SERVICE_NAME
    [[ -z "$SERVICE_NAME" ]] && log_error "Service name cannot be empty!" && sleep 2 && return

    if ! systemctl list-unit-files --type=service --all | grep -qw "$SERVICE_NAME"; then
        log_error "Service '$SERVICE_NAME' not found on this system!"
        sleep 2; return
    fi

    BASE_NAME=$(echo "$SERVICE_NAME" | sed 's/\.service$//')
    unset FIXED_INTERVAL

    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log_info "How often do you want to restart?"
    echo -e "${CYAN}1) At a specific time every day (e.g. 03:00)"
    echo -e "2) Every X hours (e.g. every 8 hours)${NC}"
    read -p "$(echo -e "${CYAN}Choose option (1 or 2): ${NC}")" TIME_MODE

    if [[ "$TIME_MODE" == "1" ]]; then
        read -p "$(echo -e "${CYAN}Enter the time (24h format, e.g. 03:00): ${NC}")" TIME_VALUE
        [[ -z "$TIME_VALUE" ]] && log_error "Time cannot be empty!" && sleep 2 && return
        if ! [[ "$TIME_VALUE" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
            log_error "Invalid time format (e.g., 03:00)."
            sleep 2; return
        fi
        ONCALENDAR="*-*-* $TIME_VALUE:00"
    elif [[ "$TIME_MODE" == "2" ]]; then
        read -p "$(echo -e "${CYAN}Enter the interval in hours (e.g. 8): ${NC}")" TIME_VALUE
        if ! [[ "$TIME_VALUE" =~ ^[0-9]+$ ]] || (( TIME_VALUE == 0 )); then
            log_error "Interval must be a positive number."
            sleep 2; return
        fi
        ONCALENDAR="hourly"
        FIXED_INTERVAL="yes"
    else
        log_error "Invalid option."
        sleep 2; return
    fi

    SCRIPT_PATH="/usr/local/bin/restart-${BASE_NAME}.sh"
    log_info "Creating script: $SCRIPT_PATH"
    cat <<EOF > "$SCRIPT_PATH"
#!/bin/bash
systemctl restart $SERVICE_NAME
EOF
    chmod +x "$SCRIPT_PATH"

    SERVICE_FILE="/etc/systemd/system/restart-${BASE_NAME}.service"
    log_info "Creating systemd service: $SERVICE_FILE"
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Auto Restart for $SERVICE_NAME

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF

    TIMER_FILE="/etc/systemd/system/restart-${BASE_NAME}.timer"
    log_info "Creating systemd timer: $TIMER_FILE"
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

    log_info "Enabling and starting timer..."
    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable --now "restart-${BASE_NAME}.timer"

    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log_success "Auto-restart configured for: $SERVICE_NAME"
    log_info "Restart style: $([ "$FIXED_INTERVAL" == "yes" ] && echo "Every $TIME_VALUE hours" || echo "Daily at $TIME_VALUE")"
    log_info "Timer status:"
    systemctl list-timers | grep "restart-${BASE_NAME}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    read -p "$(echo -e "${CYAN}Test the restart now? (y/n): ${NC}")" do_test
    if [[ "$do_test" =~ ^[Yy]$ ]]; then
        log_info "Testing service restart for $SERVICE_NAME..."
        systemctl start "restart-${BASE_NAME}.service"
        log_info "Last 10 lines of logs from $SERVICE_NAME:"
        journalctl -u "$SERVICE_NAME" -n 10 --no-pager
    else
        log_success "Done! Your service will restart automatically as scheduled."
    fi

    log_info "Press any key to return to main menu..."
    read -n 1 -s
}

# --- Remove auto-restart config ---
remove_auto_restart_configuration() {
    clear
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}${BOLD} 🗑️ Remove Auto Restart Configuration${NC}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    log_info "Timers configured by this script:"
    CONFIGURED_TIMERS=$(systemctl list-timers --no-pager | grep "restart-" | awk '{print $NF}' | sed 's/^restart-//; s/\.timer$//; s/$/\.service/' | sort -u)
    if [[ -z "$CONFIGURED_TIMERS" ]]; then
        log_warn "No configured timers found."
    else
        echo -e "${CYAN}----------------------------------------${NC}"
        echo -e "${CONFIGURED_TIMERS}" | nl -w2 -s'. ' | sed 's/^/  /'
        echo -e "${CYAN}----------------------------------------${NC}"
    fi

    read -p "$(echo -e "${CYAN}Enter the exact service name (e.g. x-ui.service): ${NC}")" SERVICE_NAME
    [[ -z "$SERVICE_NAME" ]] && log_error "Service name cannot be empty!" && sleep 2 && return

    BASE_NAME=$(echo "$SERVICE_NAME" | sed 's/\.service$//')
    TIMER_UNIT="restart-${BASE_NAME}.timer"
    SERVICE_UNIT="restart-${BASE_NAME}.service"
    SCRIPT_PATH="/usr/local/bin/restart-${BASE_NAME}.sh"
    TIMER_FILE="/etc/systemd/system/${TIMER_UNIT}"
    SERVICE_FILE="/etc/systemd/system/${SERVICE_UNIT}"

    if [[ ! -f "$TIMER_FILE" && ! -f "$SERVICE_FILE" && ! -f "$SCRIPT_PATH" ]]; then
        log_error "No auto-restart configuration found for service '$SERVICE_NAME'."
        sleep 2; return
    fi

    log_info "Attempting to remove configuration for: $SERVICE_NAME"
    if systemctl is-active --quiet "$TIMER_UNIT" || systemctl is-enabled --quiet "$TIMER_UNIT"; then
        systemctl stop "$TIMER_UNIT"
        systemctl disable "$TIMER_UNIT"
    fi
    [[ -f "$TIMER_FILE"   ]] && rm -f "$TIMER_FILE"   && log_info "Timer file deleted."
    [[ -f "$SERVICE_FILE" ]] && rm -f "$SERVICE_FILE" && log_info "Service file deleted."
    [[ -f "$SCRIPT_PATH"  ]] && rm -f "$SCRIPT_PATH"  && log_info "Script file deleted."
    systemctl daemon-reload

    log_success "Removal process complete. Please verify using 'systemctl list-timers'."
    log_info "Press any key to return to main menu..."
    read -n 1 -s
}

# --- Main program loop ---
while true; do
    display_main_menu
    read -r choice
    case "$choice" in
        1) configure_auto_restart_service ;;
        2) remove_auto_restart_configuration ;;
        0) log_info "Exiting. See you soon!"; exit 0 ;;
        *) log_error "Invalid choice. Please enter a valid option (0, 1, or 2)."; sleep 2 ;;
    esac
done
