#!/bin/bash

# Otaku Systemd Toolkit - Pro Edition by KanekiDevPro

# --- Global Variables (Theme) ---
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_VERSION="1.1.0"
SCRIPT_URL="https://raw.githubusercontent.com/KanekiDevPro/myrepo/main/kaneki_systemd_pro.sh"
SCRIPT_FILE="$0"

# --- Helper log functions ---
log_error()   { echo -e "${RED}${BOLD}❌ $1${NC}"; }
log_success() { echo -e "${GREEN}${BOLD}✅ $1${NC}"; }
log_info()    { echo -e "${CYAN}$1${NC}"; }
log_warn()    { echo -e "${YELLOW}⚠️ $1${NC}"; }

# --- Spinner for long operations ---
show_spinner() {
    local pid=$!
    local delay=0.08
    local spinstr='|/-\'
    while ps a | awk '{print $1}' | grep -q "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# --- Update script (self-update) ---
update_script() {
    log_info "Checking for updates..."
    tmpfile=$(mktemp)
    if ! curl -fsSL "$SCRIPT_URL" -o "$tmpfile"; then
        log_error "Failed to download update!"
        rm -f "$tmpfile"
        return
    fi
    if cmp -s "$tmpfile" "$SCRIPT_FILE"; then
        log_success "You are already running the latest version."
        rm -f "$tmpfile"
    else
        cp "$tmpfile" "$SCRIPT_FILE"
        chmod +x "$SCRIPT_FILE"
        log_success "Script updated! Please re-run it."
        rm -f "$tmpfile"
        exit 0
    fi
}

# --- Check root privilege ---
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root."
    log_info "Run: ${BOLD}sudo $0${NC}"
    exit 1
fi

# --- Secure service name ---
sanitize_service_name() {
    local input="$1"
    # Only allow: a-z, A-Z, 0-9, -, _, ., ending with .service
    if [[ "$input" =~ ^[a-zA-Z0-9._-]+\.service$ ]]; then
        echo "$input"
    else
        echo ""
    fi
}

# --- Select service interactively (fzf/dialog/manual) ---
choose_service_name() {
    local service_name
    if command -v fzf >/dev/null 2>&1; then
        service_name=$(systemctl list-unit-files --type=service --all | awk '{print $1}' | grep '\.service$' | fzf --prompt="Select service: ")
    elif command -v dialog >/dev/null 2>&1; then
        service_name=$(dialog --stdout --menu "Select service" 20 60 15 $(systemctl list-unit-files --type=service --all | awk '{print $1}' | grep '\.service$'))
    else
        read -p "$(echo -e "${CYAN}Enter the service name (e.g. x-ui.service): ${NC}")" service_name
    fi
    # sanitize
    sanitize_service_name "$service_name"
}

# --- Unicode bordered menu ---
display_main_menu() {
    clear
    echo -e "${MAGENTA}${BOLD}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
    echo -e "${MAGENTA}${BOLD}│         ${CYAN}${BOLD}Otaku Systemd Toolkit${NC}${MAGENTA}${BOLD}        ${CYAN}by KanekiDevPro${MAGENTA}${BOLD}         │${NC}"
    echo -e "${MAGENTA}${BOLD}├─────────────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN}│ 1) Configure auto-restart for a systemd service                            │${NC}"
    echo -e "${CYAN}│ 2) Remove auto-restart configuration for a service                         │${NC}"
    echo -e "${CYAN}│ 9) Update this script                                                      │${NC}"
    echo -e "${CYAN}│ 0) Exit                                                                    │${NC}"
    echo -e "${MAGENTA}${BOLD}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}"
    echo -n "${CYAN}➤ Your choice: ${NC}"
}

# --- Configure auto restart service ---
configure_auto_restart_service() {
    clear
    echo -e "${MAGENTA}${BOLD}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
    echo -e "${CYAN}${BOLD} 🔁 Configure auto-restart for systemd service${NC}"
    echo -e "${MAGENTA}${BOLD}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}"

    log_info "To see a list of services, run:"
    echo -e "${CYAN}  systemctl list-units --type=service | grep x${NC}"
    log_info "Example: x-ui.service, nginx.service, etc."

    # Choose service name
    SERVICE_NAME=$(choose_service_name)
    if [[ -z "$SERVICE_NAME" ]]; then
        log_error "Invalid service name!"
        sleep 2; return
    fi

    if ! systemctl list-unit-files --type=service --all | grep -qw "$SERVICE_NAME"; then
        log_error "Service '$SERVICE_NAME' not found!"
        sleep 2; return
    fi

    BASE_NAME=$(echo "$SERVICE_NAME" | sed 's/\.service$//')
    unset FIXED_INTERVAL

    # Restart mode
    echo ""
    log_info "⏱ How often do you want to restart?"
    echo -e "${CYAN}1) At a specific time every day (e.g. 03:00)"
    echo -e "2) Every X hours (e.g. every 8 hours)${NC}"
    read -p "$(echo -e "${CYAN}➤ Choose (1 or 2): ${NC}")" TIME_MODE

    if [[ "$TIME_MODE" == "1" ]]; then
        read -p "$(echo -e "${CYAN}🕒 Enter time (24h format, e.g. 03:00): ${NC}")" TIME_VALUE
        if ! [[ "$TIME_VALUE" =~ ^([01][0-9]|2[0-3]):[0-5][0-9]$ ]]; then
            log_error "Invalid time format."
            sleep 2; return
        fi
        ONCALENDAR="*-*-* $TIME_VALUE:00"
    elif [[ "$TIME_MODE" == "2" ]]; then
        read -p "$(echo -e "${CYAN}🔁 Enter interval in hours (e.g. 8): ${NC}")" TIME_VALUE
        if ! [[ "$TIME_VALUE" =~ ^[1-9][0-9]*$ ]]; then
            log_error "Invalid number."
            sleep 2; return
        fi
        ONCALENDAR="hourly"
        FIXED_INTERVAL="yes"
    else
        log_error "Invalid choice."
        sleep 2; return
    fi

    # Step 1: create script
    SCRIPT_PATH="/usr/local/bin/restart-${BASE_NAME}.sh"
    log_info "Creating script: $SCRIPT_PATH"
    cat <<EOF > "$SCRIPT_PATH"
#!/bin/bash
systemctl restart $SERVICE_NAME
EOF
    chmod +x "$SCRIPT_PATH"

    # Step 2: systemd service
    SERVICE_FILE="/etc/systemd/system/restart-${BASE_NAME}.service"
    log_info "Creating systemd service: $SERVICE_FILE"
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Auto Restart for $SERVICE_NAME

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
EOF

    # Step 3: systemd timer
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

    # Step 4: Enable timer
    log_info "Enabling timer..."
    (systemctl daemon-reexec && systemctl daemon-reload && systemctl enable --now "restart-${BASE_NAME}.timer") & show_spinner

    # Final info
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log_success "Auto-restart configured for $SERVICE_NAME!"
    log_info "Restart schedule: $([ "$FIXED_INTERVAL" == "yes" ] && echo "Every $TIME_VALUE hours" || echo "Daily at $TIME_VALUE")"
    log_info "Timer status:"
    systemctl list-timers | grep "restart-${BASE_NAME}"
    echo -e "${MAGENTA}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Optional test
    read -p "$(echo -e "${CYAN}⚙️ Test service restart now? (y/n): ${NC}")" do_test
    if [[ "$do_test" =~ ^[Yy]$ ]]; then
        log_info "Testing restart for $SERVICE_NAME..."
        systemctl start "restart-${BASE_NAME}.service"
        log_info "Last 10 lines of logs from $SERVICE_NAME:"
        journalctl -u "$SERVICE_NAME" -n 10 --no-pager
    else
        log_success "Done! Auto-restart scheduled."
    fi

    log_info "Press any key to return to the main menu..."
    read -n 1 -s
}

# --- Remove auto restart configuration ---
remove_auto_restart_configuration() {
    clear
    echo -e "${MAGENTA}${BOLD}╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮${NC}"
    echo -e "${RED}${BOLD} 🗑️ Remove auto-restart configuration${NC}"
    echo -e "${MAGENTA}${BOLD}╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯${NC}"

    log_info "Timers configured by this script:"
    CONFIGURED_TIMERS=$(systemctl list-timers --no-pager | grep "restart-" | awk '{print $NF}' | sed 's/^restart-//; s/\.timer$//; s/$/\.service/' | sort -u)
    if [[ -z "$CONFIGURED_TIMERS" ]]; then
        log_warn "No timers found."
    else
        echo -e "${CYAN}----------------------------------------${NC}"
        echo -e "${CONFIGURED_TIMERS}" | nl -w2 -s'. ' | sed 's/^/  /'
        echo -e "${CYAN}----------------------------------------${NC}"
    fi

    SERVICE_NAME=$(choose_service_name)
    if [[ -z "$SERVICE_NAME" ]]; then
        log_error "Invalid service name!"
        sleep 2; return
    fi

    BASE_NAME=$(echo "$SERVICE_NAME" | sed 's/\.service$//')
    TIMER_UNIT="restart-${BASE_NAME}.timer"
    SERVICE_UNIT="restart-${BASE_NAME}.service"
    SCRIPT_PATH="/usr/local/bin/restart-${BASE_NAME}.sh"
    TIMER_FILE="/etc/systemd/system/${TIMER_UNIT}"
    SERVICE_FILE="/etc/systemd/system/${SERVICE_UNIT}"

    if [[ ! -f "$TIMER_FILE" && ! -f "$SERVICE_FILE" && ! -f "$SCRIPT_PATH" ]]; then
        log_error "No configuration found for '$SERVICE_NAME'."
        sleep 2; return
    fi

    log_info "Removing configuration for $SERVICE_NAME..."
    if systemctl is-active --quiet "$TIMER_UNIT" || systemctl is-enabled --quiet "$TIMER_UNIT"; then
        systemctl stop "$TIMER_UNIT"
        systemctl disable "$TIMER_UNIT"
    fi

    [[ -f "$TIMER_FILE"   ]] && rm -f "$TIMER_FILE"   && log_info "Timer file removed."
    [[ -f "$SERVICE_FILE" ]] && rm -f "$SERVICE_FILE" && log_info "Service file removed."
    [[ -f "$SCRIPT_PATH"  ]] && rm -f "$SCRIPT_PATH"  && log_info "Script file removed."
    systemctl daemon-reload

    log_success "Removal process complete."
    log_info "Press any key to return to the main menu..."
    read -n 1 -s
}

# --- Main loop ---
while true; do
    display_main_menu
    read choice

    case "$choice" in
        1) configure_auto_restart_service ;;
        2) remove_auto_restart_configuration ;;
        9) update_script ;;
        0) log_info "Exiting..."; exit 0 ;;
        *) log_error "Invalid choice. Use only 0,1,2 or 9."; sleep 2 ;;
    esac
done
