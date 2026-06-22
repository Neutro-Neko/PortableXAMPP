# Portable XAMPP Configuration Documentation

This document explains the advanced configuration options for both the macOS and Linux variants of Portable XAMPP.

## Linux Configuration (`config.conf`)

When you launch `PortableXAMPP.sh` for the first time, it automatically generates a `config.conf` file in the `Linux/` directory. This file acts as the configuration brain for the script.

### Configuration Keys

*   **`APACHE_BIN`**: Set this to a direct file path (e.g., `/usr/local/apache2/bin/httpd`) to bypass `$PATH` detection and force the script to boot a custom binary. (Default: `AUTO`)
*   **`MYSQL_SVC`**: Set this to a custom `systemctl` service name (like `mysql80.service`) or a direct path to an executable shell script (like `/opt/mysql/bin/mysqld_safe`) to boot custom databases. (Default: `AUTO`)
*   **`SANDBOX`**: Completely toggle the sandboxing engine `ON` or `OFF`. (Default: `OFF`)
*   **`CUSTOM_SANDBOX`**: Override the default sandbox by providing your own custom `bwrap` or `firejail` execution wrapper string. E.g., `CUSTOM_SANDBOX="bwrap --dev-bind / /"`. (Default: `AUTO`)
*   **`SUDO_TOOL`**: Force a specific graphical privilege escalator (e.g., `pkexec`, `kdesu`, `gksudo`, `lxqt-sudo`) if your system's auto-detection fails. (Default: `AUTO`)

## macOS Configuration

On macOS, the global configuration file is stored in your native user directory: `~/Library/Application Support/PortableXAMPP/config.conf`. 
You can easily access this file by right-clicking the app icon in the Dock while it's running and selecting "Open Config".

### Configuration Keys
Unlike the Linux script, the macOS configuration file ignores binary overrides as it strictly relies on Homebrew (`/opt/homebrew/bin/`).

## Shared Configuration Keys

The following keys can be used in the `config.conf` file on **both** macOS and Linux:

*   **`TARGET_DIR`**: The absolute path to the directory you want to serve. You can choose **any** folder on your computer (e.g., `~/Documents/MyWebsites`, `/opt/projects/php`), and XAMPP will dynamically mount and serve that exact folder as your `localhost` root.
*   **`SAVE_LOGS`**: Toggle background log streaming `ON` or `OFF`. 
    *   `ON`: Apache startup and access logs will be **appended** to the files in the `logs/` directory over time.
    *   `OFF`: The logs will be **overwritten** (cleared) every time you launch the server to save disk space.

The AppleScript native launcher (`Portable XAMPP.app`) automatically relies on Homebrew (`/opt/homebrew/bin/`) for dependencies.
