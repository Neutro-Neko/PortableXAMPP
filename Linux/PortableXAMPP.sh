#!/bin/bash

# PortableXAMPP - Linux Edition
# A zero-setup, dynamic Apache/MySQL environment

ACTION=$1

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$APP_DIR/config.conf"

# Supported GUI Dialog Tools
DIALOG_TOOLS=("zenity" "kdialog" "notify-send" "xmessage")

# Supported Terminal Emulators (Format: "binary arg")
TERMINAL_TOOLS=("x-terminal-emulator -e" "gnome-terminal --" "konsole -e" "xfce4-terminal -x" "xterm -e")

# Supported Graphical Privilege Escalation Tools
SUDO_TOOLS=("pkexec" "kdesu" "gksudo" "lxqt-sudo")

# Supported MySQL Service Names
MYSQL_SERVICES=("mysql" "mariadb" "mysqld")

# 1. Detect GUI Dialog Tool
DIALOG_TOOL="cli"
for tool in "${DIALOG_TOOLS[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        DIALOG_TOOL="$tool"
        break
    fi
done

function show_message() {
    local type=$1 # info, warning, error
    local msg=$2

    # Refactored to Case (Evaluating string matching)
    case "$DIALOG_TOOL" in
        zenity)
            zenity --$type --text="$msg" 2>/dev/null
            ;;
        kdialog)
            [ "$type" = "warning" ] && type="sorry"
            kdialog --msgbox "$msg" 2>/dev/null
            ;;
        notify-send)
            notify-send "PortableXAMPP [$type]" "$msg" 2>/dev/null
            ;;
        xmessage)
            xmessage -center "[$type] $msg" 2>/dev/null
            ;;
        *)
            if [ -t 1 ]; then
                echo "[$type] $msg"
            else
                local term_cmd="echo 'PortableXAMPP [$type]:'; echo '$msg'; echo ''; read -p 'Press Enter to close...'"
                for term_opts in "${TERMINAL_TOOLS[@]}"; do
                    term="${term_opts%% *}"
                    opts="${term_opts#* }"
                    if command -v "$term" >/dev/null 2>&1; then
                        $term $opts bash -c "$term_cmd"
                        break
                    fi
                done
            fi
            ;;
    esac
}

function prompt_open_editor() {
    local file=$1
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$file"
    elif [ -t 1 ]; then
        if command -v nano >/dev/null 2>&1; then nano "$file"
        else vi "$file"; fi
    fi
}

# 1.5 Parse Config and Detect Root Tool (Optimized single-pass read)
TARGET_DIR=""
SANDBOX_OPT="OFF"
SUDO_TOOL="AUTO"
SAVE_LOGS="OFF"
APACHE_BIN="AUTO"
MYSQL_SVC="AUTO"

if [ -f "$CONFIG_FILE" ]; then
    TARGET_DIR=$(head -n 1 "$CONFIG_FILE" | xargs)
    while IFS='=' read -r key value; do
        val=$(echo "$value" | xargs)
        case "$key" in
            SANDBOX) SANDBOX_OPT="$val" ;;
            SUDO_TOOL) SUDO_TOOL="$val" ;;
            SAVE_LOGS) SAVE_LOGS="$val" ;;
            APACHE_BIN) APACHE_BIN="$val" ;;
            MYSQL_SVC) MYSQL_SVC="$val" ;;
        esac
    done < "$CONFIG_FILE"
fi

if [ -z "$SUDO_TOOL" ] || [ "$SUDO_TOOL" = "AUTO" ]; then
    SUDO_TOOL="sudo"
    for tool in "${SUDO_TOOLS[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            SUDO_TOOL="$tool"
            break
        fi
    done
fi

function check_sudo_tty() {
    local action_name=$1
    if [ "$EUID" -ne 0 ] && [ "$SUDO_TOOL" = "sudo" ] && [ ! -t 1 ]; then
        show_message "error" "Cannot $action_name: Root privileges required, but no graphical sudo handler was found and no terminal is attached. Please launch via terminal or install pkexec."
        exit 1
    fi
}

# 2. Main Script Routing (Refactored to Universal Case Switch)
case "$ACTION" in
    stop)
        echo "Stopping XAMPP servers..."
        
        if [ "$APACHE_BIN" = "AUTO" ] || [ -z "$APACHE_BIN" ]; then
            APACHE_BIN=""
            if command -v apache2 >/dev/null 2>&1; then APACHE_BIN="apache2";
            elif command -v httpd >/dev/null 2>&1; then APACHE_BIN="httpd"; fi
        fi
        
        if [ -n "$APACHE_BIN" ]; then
            if [ "$EUID" -ne 0 ] && command -v "$SUDO_TOOL" >/dev/null 2>&1; then
                check_sudo_tty "stop Apache"
                $SUDO_TOOL "$APACHE_BIN" -k stop >/dev/null 2>&1
            else
                "$APACHE_BIN" -k stop >/dev/null 2>&1
            fi
        fi
        
        # Stop MySQL (Optimized Universal Loop)
        if [ "$MYSQL_SVC" != "AUTO" ] && [ -n "$MYSQL_SVC" ]; then
            local stop_cmd=""
            if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$MYSQL_SVC"; then stop_cmd="systemctl stop $MYSQL_SVC"
            elif [ -x "/etc/init.d/$MYSQL_SVC" ] && service "$MYSQL_SVC" status 2>/dev/null | grep -iq "running"; then stop_cmd="service $MYSQL_SVC stop"
            elif [ -x "$MYSQL_SVC" ]; then stop_cmd="\"$MYSQL_SVC\" stop"
            fi
            
            if [ -n "$stop_cmd" ]; then
                check_sudo_tty "stop MySQL"
                eval "$SUDO_TOOL $stop_cmd >/dev/null 2>&1"
            fi
        else
            for svc in "${MYSQL_SERVICES[@]}"; do
                local stop_cmd=""
                if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$svc"; then stop_cmd="systemctl stop $svc"
                elif [ -x "/etc/init.d/$svc" ] && service "$svc" status 2>/dev/null | grep -iq "running"; then stop_cmd="service $svc stop"
                fi
                
                if [ -n "$stop_cmd" ]; then
                    check_sudo_tty "stop MySQL"
                    $SUDO_TOOL $stop_cmd >/dev/null 2>&1
                    break
                fi
            done
        fi
        
        show_message "info" "XAMPP servers stopped."
        exit 0
        ;;

    start)
        # 3.0 Auto-Patch the .desktop file for Universal Compatibility
        DESKTOP_FILE="$APP_DIR/PortableXAMPP.desktop"
        if [ -f "$DESKTOP_FILE" ] && grep -q "^Exec=%k" "$DESKTOP_FILE"; then
            sed -i -e "s|^Exec=.*|Exec=\"$APP_DIR/PortableXAMPP.sh\" start|" \
                   -e "s|^Icon=.*|Icon=$APP_DIR/icon.svg|" "$DESKTOP_FILE"
            chmod +x "$DESKTOP_FILE" 2>/dev/null || true
            command -v gio >/dev/null 2>&1 && gio set "$DESKTOP_FILE" metadata::trusted true 2>/dev/null
        fi

        # 3.1 Config Generation & Validation (Optimized multi-line generation)
        if [ ! -f "$CONFIG_FILE" ]; then
            cat <<EOF > "$CONFIG_FILE"
INSERT_YOUR_WEB_FOLDER_PATH_HERE
SANDBOX=OFF
SUDO_TOOL=AUTO
SAVE_LOGS=OFF
APACHE_BIN=AUTO
MYSQL_SVC=AUTO
EOF
            TARGET_DIR="INSERT_YOUR_WEB_FOLDER_PATH_HERE"
            SANDBOX_OPT="OFF"
            SUDO_TOOL="AUTO"
            SAVE_LOGS="OFF"
            APACHE_BIN="AUTO"
            MYSQL_SVC="AUTO"
        fi
        
        if [ -z "$TARGET_DIR" ] || [ "$TARGET_DIR" = "INSERT_YOUR_WEB_FOLDER_PATH_HERE" ]; then
            show_message "warning" "Configuration Required: Please paste the absolute path to your project folder into the configuration file that will now open, save it, and relaunch."
            prompt_open_editor "$CONFIG_FILE"
            exit 1
        fi
        
        if [ ! -d "$TARGET_DIR" ]; then
            show_message "error" "Invalid Path: The directory '$TARGET_DIR' does not exist."
            prompt_open_editor "$CONFIG_FILE"
            exit 1
        fi

        # 3.2 Dependency Detection
        if [ "$APACHE_BIN" = "AUTO" ] || [ -z "$APACHE_BIN" ]; then
            APACHE_BIN=""
            if command -v apache2 >/dev/null 2>&1; then APACHE_BIN="apache2";
            elif command -v httpd >/dev/null 2>&1; then APACHE_BIN="httpd"; fi
        fi
        
        if [ -z "$APACHE_BIN" ] || ! command -v "$APACHE_BIN" >/dev/null 2>&1; then
            show_message "error" "Apache (apache2 or httpd) is not installed or the custom APACHE_BIN path is invalid. Please check your config.conf or install via your package manager."
            exit 1
        fi

        if ! command -v php >/dev/null 2>&1; then
            show_message "error" "PHP is not installed. Please install it via your package manager."
            exit 1
        fi

        if ! command -v mysql >/dev/null 2>&1 && ! command -v mariadb >/dev/null 2>&1; then
            show_message "warning" "MySQL/MariaDB client is not installed. Database features may be unavailable."
        fi

        # 3.3 UI Template Injection
        UI_TEMPLATE_DIR="$APP_DIR/UI_Template"
        if [ -d "$UI_TEMPLATE_DIR" ]; then
            cp -Rn "$UI_TEMPLATE_DIR/.XAMPPconfig" "$TARGET_DIR" 2>/dev/null || true
            cp -n "$UI_TEMPLATE_DIR/.htaccess" "$TARGET_DIR/.htaccess" 2>/dev/null || true
        fi

        # 3.4 Micro-Config & Internal Log Generation
        MICRO_CONFIG="$TARGET_DIR/.XAMPPconfig/overrides/micro.conf"
        LOG_DIR="$APP_DIR/logs"
        mkdir -p "$(dirname "$MICRO_CONFIG")"
        mkdir -p "$LOG_DIR"
        
        if [ "$SAVE_LOGS" != "ON" ]; then
            > "$LOG_DIR/apache_error.log"
            > "$LOG_DIR/apache_access.log"
            > "$LOG_DIR/startup.log"
            REDIR=">"
        else
            REDIR=">>"
        fi

        # Generate Apache Config (Optimized DRY architecture)
        {
            if [ "$SANDBOX_OPT" = "ON" ]; then
                echo "User $USER"
                echo "Group $(id -gn)"
            fi
            cat <<EOF
DocumentRoot "$TARGET_DIR"
ErrorLog "$LOG_DIR/apache_error.log"
CustomLog "$LOG_DIR/apache_access.log" common
<Directory "$TARGET_DIR">
Options Indexes FollowSymLinks
AllowOverride All
Require all granted
</Directory>
EOF
        } > "$MICRO_CONFIG"

        # 3.5 Boot MySQL (Optimized Universal Loop)
        if [ "$MYSQL_SVC" != "AUTO" ] && [ -n "$MYSQL_SVC" ]; then
            local start_cmd=""
            if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q "^${MYSQL_SVC}\.service"; then
                if ! systemctl is-active --quiet "$MYSQL_SVC"; then start_cmd="systemctl start $MYSQL_SVC"; fi
            elif [ -x "/etc/init.d/$MYSQL_SVC" ]; then
                if ! service "$MYSQL_SVC" status 2>/dev/null | grep -iq "running"; then start_cmd="service $MYSQL_SVC start"; fi
            elif [ -x "$MYSQL_SVC" ]; then
                start_cmd="\"$MYSQL_SVC\" start &"
            else
                show_message "error" "Custom MYSQL_SVC '$MYSQL_SVC' not found as a systemctl/init.d service or executable script."
            fi
            
            if [ -n "$start_cmd" ]; then
                check_sudo_tty "start MySQL"
                eval "$SUDO_TOOL $start_cmd >/dev/null 2>&1"
            fi
        else
            for svc in "${MYSQL_SERVICES[@]}"; do
                local start_cmd=""
                if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q "^${svc}\.service"; then
                    if ! systemctl is-active --quiet "$svc"; then start_cmd="systemctl start $svc"; fi
                elif [ -x "/etc/init.d/$svc" ]; then
                    if ! service "$svc" status 2>/dev/null | grep -iq "running"; then start_cmd="service $svc start"; fi
                fi
                
                if [ -n "$start_cmd" ]; then
                    check_sudo_tty "start MySQL"
                    $SUDO_TOOL $start_cmd >/dev/null 2>&1
                    break
                fi
            done
        fi

        # 3.6 Base Apache Command
        EXEC_CMD="$APACHE_BIN -c 'Include \"$MICRO_CONFIG\"' -k start"

        # 3.7 Sandboxing (Wrap base command and safely mount application logs directory)
        if [ "$SANDBOX_OPT" = "ON" ]; then
            if command -v bwrap >/dev/null 2>&1; then
                EXEC_CMD="bwrap --ro-bind / / --bind \"$TARGET_DIR\" \"$TARGET_DIR\" --bind \"$LOG_DIR\" \"$LOG_DIR\" --bind /tmp /tmp --dev /dev --proc /proc --unshare-all --share-net $EXEC_CMD"
            elif command -v firejail >/dev/null 2>&1; then
                EXEC_CMD="firejail --noprofile --whitelist=\"$TARGET_DIR\" --whitelist=\"$LOG_DIR\" $EXEC_CMD"
            else
                show_message "warning" "Sandboxing is ON in config, but neither bwrap nor firejail was found. Please install one or turn SANDBOX=OFF. Halting boot."
                exit 1
            fi
        fi

        # 3.8 Privilege Escalation
        if [ "$EUID" -ne 0 ] && [[ "$APACHE_BIN" == "apache2" ]]; then
            if command -v "$SUDO_TOOL" >/dev/null 2>&1; then
                check_sudo_tty "start Apache"
                EXEC_CMD="$SUDO_TOOL $EXEC_CMD"
            else
                show_message "error" "Root privileges required, but the configured root tool ($SUDO_TOOL) is not installed."
                exit 1
            fi
        fi

        # Execute and cleanly route output using dynamic redirection operators and ternary short-circuit
        eval "$EXEC_CMD $REDIR \"$LOG_DIR/startup.log\" 2>&1" && \
            show_message "info" "XAMPP servers are active. Web root: $TARGET_DIR" || \
            show_message "error" "Failed to start Apache. Check the logs at: $LOG_DIR/startup.log"
        ;;

    *)
        echo "Usage: $0 [start|stop]"
        exit 1
        ;;
esac
