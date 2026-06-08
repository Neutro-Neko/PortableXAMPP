# Portable XAMPP

Portable XAMPP is a lightweight, macOS-native alternative to traditional XAMPP. By leveraging Homebrew's robust libraries instead of shipping its own compiled binaries, it maintains an incredibly small footprint while running natively on Apple Silicon and Intel Macs.

## ✨ Features

- **Homebrew Powered**: Uses your system's Homebrew installations of `httpd`, `mysql`, and `php`. If you don't have them installed, the app automatically detects this and installs them for you via a Terminal script on the first launch.
- **macOS Native Experience**: Comes with a proper macOS squircle app icon and integrates perfectly with the OS. There is no clunky management UI: simply start the app to start the servers, and quit the app from the Dock to stop them.
- **Zero-Setup Configuration**: On your first launch, the app automatically generates a configuration file and natively prompts you to set your preferred `localhost` working directory.
- **Sandboxed Security**: Apache is restricted using a custom macOS Seatbelt kernel profile (`xampp-jail.sb`), dynamically tied to the specific folder you configure, triggering native TCC permission dialogs for maximum privacy.
- **Beautiful Localhost UI**: The default localhost directory index has been fully stylized with custom CSS and VSCode file icons. The UI assets are automatically injected into your web directory as `.XAMPPconfig` on the first launch. You can easily customize this by adding your own files to the `.XAMPPconfig/overrides` directory (like an `override.css` or custom icons) without modifying the default theme. *(Note: The main XAMPP icon cannot be overridden — it's not a bug, it's a feature!)*
- **Clean phpMyAdmin**: If you place a symlink to phpMyAdmin inside your localhost directory, it renders with its proper name and database icon instead of looking like a generic folder.

## 🚀 Usage

1. Open `PortableXAMPP.app`.
2. On the first launch, it will ask you to provide the absolute path to your web development folder. It will open `web_path.conf` in TextEdit—simply paste your path, save, and relaunch.
3. macOS will ask you for permission to access that folder.
4. Your servers are now running! Visit `http://localhost:8080` in your browser. _(Note: It defaults to port `8080` instead of `80` to avoid requiring root/sudo privileges on macOS)._
5. When you're done working, just **Quit** the app from the macOS Dock to shut down the Apache and MySQL servers.

## ⚙️ Configuration

You can easily change your working directory or adjust port configurations by editing the `web_path.conf` file located inside the app bundle (`PortableXAMPP.app/Contents/Resources/web_path.conf`).
