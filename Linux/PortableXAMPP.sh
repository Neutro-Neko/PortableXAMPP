#!/bin/bash

# PortableXAMPP - Linux Edition
# A zero-setup, dynamic Apache/MySQL environment

ACTION=$1
if [ -z "$ACTION" ]; then
    echo "Usage: $0 [start|stop]"
    exit 1
fi

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$APP_DIR/web_path.conf"

# 1. Detect GUI Dialog Tool
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
    if [ "$DIALOG_TOOL" = "zenity" ]; then
        zenity --$type --text="$msg" 2>/dev/null
    elif [ "$DIALOG_TOOL" = "kdialog" ]; then
        if [ "$type" = "warning" ]; then type="sorry"; fi
        kdialog --msgbox "$msg" 2>/dev/null
    elif [ "$DIALOG_TOOL" = "notify-send" ]; then
        notify-send "PortableXAMPP [$type]" "$msg" 2>/dev/null
    elif [ "$DIALOG_TOOL" = "xmessage" ]; then
        xmessage -center "[$type] $msg" 2>/dev/null
    else
        # If launched from an actual terminal, just print it normally
        if [ -t 1 ]; then
            echo "[$type] $msg"
        else
            # If launched from GUI, hunt for a terminal to pop open
            local term_cmd="echo 'PortableXAMPP [$type]:'; echo '$msg'; echo ''; read -p 'Press Enter to close...'"
            
            if command -v x-terminal-emulator >/dev/null 2>&1; then x-terminal-emulator -e bash -c "$term_cmd"
            elif command -v gnome-terminal >/dev/null 2>&1; then gnome-terminal -- bash -c "$term_cmd"
            elif command -v konsole >/dev/null 2>&1; then konsole -e bash -c "$term_cmd"
            elif command -v xfce4-terminal >/dev/null 2>&1; then xfce4-terminal -x bash -c "$term_cmd"
            elif command -v xterm >/dev/null 2>&1; then xterm -e bash -c "$term_cmd"
            fi
        fi
    fi
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

# 1.5 Parse Config and Detect Root Tool
TARGET_DIR=""
SANDBOX_OPT="OFF"
SUDO_TOOL="AUTO"

if [ -f "$CONFIG_FILE" ]; then
    TARGET_DIR=$(grep -v -E "SANDBOX=|SUDO_TOOL=" "$CONFIG_FILE" | head -n 1 | xargs)
    SANDBOX_OPT=$(grep "SANDBOX=" "$CONFIG_FILE" | cut -d'=' -f2 | xargs)
    SUDO_TOOL=$(grep "SUDO_TOOL=" "$CONFIG_FILE" | cut -d'=' -f2 | xargs)
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

# 2. Stop Action
if [ "$ACTION" = "stop" ]; then
    echo "Stopping XAMPP servers..."
    
    APACHE_BIN=""
    if command -v apache2 >/dev/null 2>&1; then APACHE_BIN="apache2";
    elif command -v httpd >/dev/null 2>&1; then APACHE_BIN="httpd"; fi
    
    if [ -n "$APACHE_BIN" ]; then
        # On Linux, standard apache2 requires root to stop unless configured for user space
        if [ "$EUID" -ne 0 ] && command -v "$SUDO_TOOL" >/dev/null 2>&1; then
            check_sudo_tty "stop Apache"
            $SUDO_TOOL $APACHE_BIN -k stop >/dev/null 2>&1
        else
            $APACHE_BIN -k stop >/dev/null 2>&1
        fi
    fi
    
    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet mysql || systemctl is-active --quiet mariadb || systemctl is-active --quiet mysqld; then
            check_sudo_tty "stop MySQL"
            if systemctl is-active --quiet mysql; then $SUDO_TOOL systemctl stop mysql;
            elif systemctl is-active --quiet mariadb; then $SUDO_TOOL systemctl stop mariadb;
            elif systemctl is-active --quiet mysqld; then $SUDO_TOOL systemctl stop mysqld; fi
        fi
    fi
    
    show_message "info" "XAMPP servers stopped."
    exit 0
fi

# 3. Start Action
if [ "$ACTION" = "start" ]; then
    # 3.1 Config Generation & Validation
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "INSERT_YOUR_WEB_FOLDER_PATH_HERE" > "$CONFIG_FILE"
        echo "SANDBOX=OFF" >> "$CONFIG_FILE"
        echo "SUDO_TOOL=AUTO" >> "$CONFIG_FILE"
        
        # Reset variables for validation check
        TARGET_DIR="INSERT_YOUR_WEB_FOLDER_PATH_HERE"
        SANDBOX_OPT="OFF"
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
    # Copy from the adjacent Linux UI_Template folder
    UI_TEMPLATE_DIR="$APP_DIR/UI_Template"
    if [ -d "$UI_TEMPLATE_DIR" ]; then
        cp -Rn "$UI_TEMPLATE_DIR/.XAMPPconfig" "$TARGET_DIR" 2>/dev/null || true
    fi

    # 3.4 Micro-Config Generation
    MICRO_CONFIG="$TARGET_DIR/.XAMPPconfig/overrides/micro.conf"
    mkdir -p "$(dirname "$MICRO_CONFIG")"
    
    if [ "$SANDBOX_OPT" = "ON" ]; then
        printf 'User %s\nGroup %s\nDocumentRoot "%s"\n<Directory "%s">\nOptions Indexes FollowSymLinks\nAllowOverride All\nRequire all granted\n</Directory>\n' "$USER" "$(id -gn)" "$TARGET_DIR" "$TARGET_DIR" > "$MICRO_CONFIG"
    else
        printf 'DocumentRoot "%s"\n<Directory "%s">\nOptions Indexes FollowSymLinks\nAllowOverride All\nRequire all granted\n</Directory>\n' "$TARGET_DIR" "$TARGET_DIR" > "$MICRO_CONFIG"
    fi

    # 3.5 Boot MySQL
    if command -v systemctl >/dev/null 2>&1; then
        if ! systemctl is-active --quiet mysql && ! systemctl is-active --quiet mariadb && ! systemctl is-active --quiet mysqld; then
            if systemctl list-unit-files | grep -q "^mysql.service" || systemctl list-unit-files | grep -q "^mariadb.service" || systemctl list-unit-files | grep -q "^mysqld.service"; then
                check_sudo_tty "start MySQL"
                if systemctl list-unit-files | grep -q "^mysql.service"; then $SUDO_TOOL systemctl start mysql;
                elif systemctl list-unit-files | grep -q "^mariadb.service"; then $SUDO_TOOL systemctl start mariadb;
                elif systemctl list-unit-files | grep -q "^mysqld.service"; then $SUDO_TOOL systemctl start mysqld; fi
            fi
        fi
    fi

    # 3.6 Base Apache Command
    EXEC_CMD="$APACHE_BIN -c 'Include \"$MICRO_CONFIG\"' -k start"

    # 3.7 Sandboxing (Wrap the base command first)
    if [ "$SANDBOX_OPT" = "ON" ]; then
        if command -v bwrap >/dev/null 2>&1; then
            EXEC_CMD="bwrap --ro-bind / / --bind \"$TARGET_DIR\" \"$TARGET_DIR\" --bind /tmp /tmp --dev /dev --proc /proc --unshare-all --share-net $EXEC_CMD"
        elif command -v firejail >/dev/null 2>&1; then
            EXEC_CMD="firejail --noprofile --whitelist=\"$TARGET_DIR\" $EXEC_CMD"
        else
            show_message "warning" "Sandboxing is ON in config, but neither bwrap nor firejail was found. Please install one 'the Linux way' or turn SANDBOX=OFF. Halting boot."
            exit 1
        fi
    fi

    # 3.8 Privilege Escalation (Wrap the sandboxed command)
    # Require root if running system-wide apache2
    if [ "$EUID" -ne 0 ] && [[ "$APACHE_BIN" == "apache2" ]]; then
        if command -v "$SUDO_TOOL" >/dev/null 2>&1; then
            check_sudo_tty "start Apache"
            EXEC_CMD="$SUDO_TOOL $EXEC_CMD"
        else
            show_message "error" "Root privileges required, but the configured root tool ($SUDO_TOOL) is not installed."
            exit 1
        fi
    fi

    eval "$EXEC_CMD >/dev/null 2>&1"
    
    if [ $? -eq 0 ]; then
        show_message "info" "XAMPP servers are active. Web root: $TARGET_DIR"
    else
        show_message "error" "Failed to start Apache. Try running without sandboxing or check permissions."
    fi
fi
