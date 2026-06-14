<h1 style="display: flex; align-items: center;">
<img alt="Portable XAMPP Logo" src="./assets/xampp.svg" width="72" valign="middle">
  &nbsp;Portable XAMPP
</h1>

Portable XAMPP is a lightweight, zero-setup alternative to traditional XAMPP built for macOS and Linux. By leveraging your system's native package managers (`brew`, `apt`, `dnf`) instead of shipping its own compiled binaries, it maintains an incredibly small footprint while running natively on your hardware.

## ✨ Features

- **Homebrew Powered**: Uses your system's Homebrew installations of `httpd`, `mysql`, and `php`. If you don't have them installed, the app automatically detects this and installs them for you via a Terminal script on the first launch.
- **macOS Native Experience**: Comes with a proper macOS squircle app icon and integrates perfectly with the OS. There is no clunky management UI: simply start the app to start the servers, and quit the app from the Dock to stop them.
- **Zero-Setup Configuration (Micro-Config)**: On your first launch, the app automatically generates a configuration file and natively prompts you to set your preferred `localhost` working directory. Under the hood, it seamlessly injects a dynamic `micro.conf` into Apache at runtime, meaning your global Homebrew configuration is never modified and the app is 100% crash-proof when moved between computers.
- **Sandboxed Security**: Apache is restricted using a custom macOS Seatbelt kernel profile (`xampp-jail.sb`), dynamically tied to the specific folder you configure, triggering native TCC permission dialogs for maximum privacy.
- **Beautiful Localhost UI**: The default localhost directory index has been fully stylized with custom CSS and VSCode file icons. It utilizes lightning-fast synchronous fallbacks so custom override icons render instantly with zero visual "blinking" delay. The UI assets are automatically injected into your web directory as `.XAMPPconfig` on the first launch. You can easily customize this by adding your own files to the `.XAMPPconfig/overrides` directory without modifying the default theme. _(Note: The main XAMPP icon cannot be overridden — it's not a bug, it's a feature!)_
- **Clean phpMyAdmin**: If you place a symlink to phpMyAdmin inside your localhost directory, it renders with its proper name and database icon instead of looking like a generic folder.

## 🚀 Usage

### <img src="./assets/apple-aligned.svg" width="32" alt="macOS" valign="middle"> macOS Edition

1. Open `PortableXAMPP.app`.
2. On the first launch, it will ask you to provide the absolute path to your web development folder. It will open `web_path.conf` in TextEdit—simply paste your path, save, and relaunch.
3. macOS will ask you for permission to access that folder.
4. Your servers are now running! Visit `http://localhost:8080` in your browser. _(Note: It defaults to port `8080` instead of `80` to avoid requiring root/sudo privileges on macOS)._
5. When you're done working, just **Quit** the app from the macOS Dock to shut down the Apache and MySQL servers.

### <img src="./assets/linux-aligned.svg" width="32" alt="Linux" valign="middle"> Linux Edition

1. Navigate to the `Linux/` folder.
2. Make the script executable: `chmod +x PortableXAMPP.sh`
3. Launch it via the terminal (`./PortableXAMPP.sh start`) or use the provided `PortableXAMPP.desktop` entry.
4. On the first launch, a native GUI prompt (Zenity/KDialog) will ask you to paste your target web directory into `web_path.conf`.
5. The script auto-detects your package manager, ensures dependencies are met, and dynamically wraps the server in a secure `bwrap` or `firejail` sandbox if configured.

## ⚙️ Configuration

You can change your working directory by editing the `web_path.conf` file located inside the app bundle (`PortableXAMPP.app/Contents/Resources/web_path.conf`).

Because of the dynamic Micro-Config architecture, the app automatically handles rerouting Apache's `DocumentRoot` for you on every launch. If you need to make deep, global server adjustments (like changing ports), you make those natively in your global Homebrew `/opt/homebrew/etc/httpd/httpd.conf` file.

## ⚖️ Disclaimer & Acknowledgements

- **XAMPP Name & Logo**: The app icon is a slightly modified version of the official XAMPP logo to be a squircle. "XAMPP" and the XAMPP logo are trademarks of Apache Friends / Bitnami. This project is an independent, unofficial, open-source macOS alternative and is **not** affiliated with, maintained by, or endorsed by Apache Friends (yet).
- **UI Icons**: The file icons used in the localhost UI are sourced from the VS Code Material Icon Theme (MIT Licensed). The individual language logos depicted in those icons remain trademarks of their respective languages/organizations.
