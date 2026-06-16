#!/bin/bash

# PortableXAMPP - Linux Edition
# A zero-setup, dynamic Apache/MySQL environment

ACTION=$1

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$APP_DIR/web_path.conf"

# 1. Detect GUI Dialog Tool (Requires command execution, kept as if/elif)
DIALOG_TOOL="cli"
if command -v zenity >/dev/null 2>&1; then
    DIALOG_TOOL="zenity"
elif command -v kdialog >/dev/null 2>&1; then
    DIALOG_TOOL="kdialog"
elif command -v notify-send >/dev/null 2>&1; then
    DIALOG_TOOL="notify-send"
elif command -v xmessage >/dev/null 2>&1; then
    DIALOG_TOOL="xmessage"
fi

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
                if command -v x-terminal-emulator >/dev/null 2>&1; then x-terminal-emulator -e bash -c "$term_cmd"
                elif command -v gnome-terminal >/dev/null 2>&1; then gnome-terminal -- bash -c "$term_cmd"
                elif command -v konsole >/dev/null 2>&1; then konsole -e bash -c "$term_cmd"
                elif command -v xfce4-terminal >/dev/null 2>&1; then xfce4-terminal -x bash -c "$term_cmd"
                elif command -v xterm >/dev/null 2>&1; then xterm -e bash -c "$term_cmd"
                fi
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

if [ -f "$CONFIG_FILE" ]; then
    TARGET_DIR=$(head -n 1 "$CONFIG_FILE" | xargs)
    while IFS='=' read -r key value; do
        val=$(echo "$value" | xargs)
        case "$key" in
            SANDBOX) SANDBOX_OPT="$val" ;;
            SUDO_TOOL) SUDO_TOOL="$val" ;;
            SAVE_LOGS) SAVE_LOGS="$val" ;;
        esac
    done < "$CONFIG_FILE"
fi

if [ -z "$SUDO_TOOL" ] || [ "$SUDO_TOOL" = "AUTO" ]; then
    SUDO_TOOL="sudo"
    if command -v pkexec >/dev/null 2>&1; then SUDO_TOOL="pkexec";
    elif command -v kdesu >/dev/null 2>&1; then SUDO_TOOL="kdesu";
    elif command -v gksudo >/dev/null 2>&1; then SUDO_TOOL="gksudo";
    elif command -v lxqt-sudo >/dev/null 2>&1; then SUDO_TOOL="lxqt-sudo"; fi
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
        
        APACHE_BIN=""
        if command -v apache2 >/dev/null 2>&1; then APACHE_BIN="apache2";
        elif command -v httpd >/dev/null 2>&1; then APACHE_BIN="httpd"; fi
        
        if [ -n "$APACHE_BIN" ]; then
            if [ "$EUID" -ne 0 ] && command -v "$SUDO_TOOL" >/dev/null 2>&1; then
                check_sudo_tty "stop Apache"
                $SUDO_TOOL $APACHE_BIN -k stop >/dev/null 2>&1
            else
                $APACHE_BIN -k stop >/dev/null 2>&1
            fi
        fi
        
        # Stop MySQL (Optimized Universal Loop)
        for svc in mysql mariadb mysqld; do
            if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$svc"; then
                check_sudo_tty "stop MySQL"
                $SUDO_TOOL systemctl stop "$svc"
                break
            elif [ -x "/etc/init.d/$svc" ] && service "$svc" status 2>/dev/null | grep -iq "running"; then
                check_sudo_tty "stop MySQL"
                $SUDO_TOOL service "$svc" stop >/dev/null 2>&1
                break
            fi
        done
        
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
EOF
            TARGET_DIR="INSERT_YOUR_WEB_FOLDER_PATH_HERE"
            SANDBOX_OPT="OFF"
            SUDO_TOOL="AUTO"
            SAVE_LOGS="OFF"
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
        APACHE_BIN=""
        if command -v apache2 >/dev/null 2>&1; then APACHE_BIN="apache2";
        elif command -v httpd >/dev/null 2>&1; then APACHE_BIN="httpd"; fi
        
        if [ -z "$APACHE_BIN" ]; then
            show_message "error" "Apache (apache2 or httpd) is not installed. Please install it via your package manager (apt, dnf, pacman, brew)."
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
        for svc in mysql mariadb mysqld; do
            if command -v systemctl >/dev/null 2>&1 && systemctl list-unit-files | grep -q "^${svc}\.service"; then
                if ! systemctl is-active --quiet "$svc"; then
                    check_sudo_tty "start MySQL"
                    $SUDO_TOOL systemctl start "$svc"
                fi
                break
            elif [ -x "/etc/init.d/$svc" ]; then
                if ! service "$svc" status 2>/dev/null | grep -iq "running"; then
                    check_sudo_tty "start MySQL"
                    $SUDO_TOOL service "$svc" start >/dev/null 2>&1
                fi
                break
            fi
        done

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

        # Execute and cleanly route output using dynamic redirection operators
        eval "$EXEC_CMD $REDIR \"$LOG_DIR/startup.log\" 2>&1"
        
        if [ $? -eq 0 ]; then
            show_message "info" "XAMPP servers are active. Web root: $TARGET_DIR"
        else
            show_message "error" "Failed to start Apache. Check the logs at: $LOG_DIR/startup.log"
        fi
        ;;

    *)
        echo "Usage: $0 [start|stop]"
        exit 1
        ;;
esac
