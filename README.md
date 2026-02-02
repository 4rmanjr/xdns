# xdns - Advanced Linux DNS Manager

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Linux-FCC624?style=flat-square&logo=linux&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)
![Version](https://img.shields.io/badge/Version-3.3.0%20Production-green?style=flat-square)

**xdns** is a robust, interactive, and safety-focused command-line tool for managing DNS configurations on Linux systems. It is designed to replace manual editing of `/etc/resolv.conf` with a secure, atomic, and feature-rich workflow.

Unlike basic scripts, **xdns** treats system stability as a priority. It features pre-flight connectivity checks, atomic file operations, immutable locking mechanisms, and "Golden Image" backups to ensure you never lose your original network configuration.

## 🆕 What's New in v3.3.0

- **🌍 New Distros:** Added support for Gentoo, Void Linux, and Solus
- **🔌 Network Manager:** Enhanced support for systemd-networkd and ConnMan
- **🔒 Persistent DNS:** Lock now creates NetworkManager override to survive WiFi reconnects
- **🔒 Security:** Fixed ShellCheck SC2207 word splitting vulnerability
- **⚡ Improved:** Better package name mapping for Gentoo (atom format)

<details>
<summary>v3.2.0 Changes</summary>

- Browser DNS resolution fix (systemd-resolved restart)
- Restore DNS "corrupt" error fix
- Smart dependency management
- Temp files with restrictive umask (077)
- Smarter backup logic
</details>

---

## 🚀 Key Features

*   **⚡ Latency Benchmarking (Speed Test)**
    *   Automatically pings available DNS providers from your location to find the fastest server (lowest ms).
*   **🔒 Immutable Locking**
    *   Option to lock `/etc/resolv.conf` using `chattr +i`. This prevents NetworkManager, DHCP, or systemd from overwriting your DNS settings after a reboot.
*   **🛡️ Enterprise-Grade Safety**
    *   **Pre-Flight Ping:** Verifies connectivity to the target DNS server *before* applying changes. If the server is unreachable, the operation is aborted to prevent internet loss.
    *   **Atomic Writes:** Uses temp-file-and-move strategy to prevent file corruption during write operations.
    *   **Smart Dependencies:** Automatically detects missing tools (`bc`, `ping`) and offers to install them using your system's package manager (`apt`, `pacman`, `dnf`, etc.).
*   **💾 Smart Backup & Restore**
    *   **Golden Image Backup:** Creates a permanent backup of your *original* system configuration upon first run.
    *   **Symlink Awareness:** Correctly handles modern distros (Ubuntu/Fedora) where `/etc/resolv.conf` is a symlink to `systemd-resolved`. It restores the link, not just the content.
*   **🧹 Auto-Flush Cache**
    *   Automatically detects and flushes DNS cache for `systemd-resolve`, `resolvectl`, `nscd`, and `dnsmasq`.
*   **🖥️ CLI & Interactive Mode**
    *   Full command-line support for scripting and automation, plus interactive menu for manual use.

## 📦 Installation

You can install `xdns` globally on your system with a few commands:

```bash
# Clone the repository
git clone https://github.com/4rmanjr/xdns.git

# Enter directory
cd xdns

# Make executable & move to bin (Global Access)
chmod +x xdns
sudo mv xdns /usr/local/bin/xdns

# Clean up
cd .. && rm -rf xdns
```

### Shell Completion (Optional)

Enable tab completion for faster command entry:

**Bash:**
```bash
sudo cp completions/xdns.bash /etc/bash_completion.d/xdns
# Restart terminal or: source /etc/bash_completion.d/xdns
```

**Zsh:**
```bash
sudo cp completions/_xdns /usr/share/zsh/site-functions/_xdns
# Restart terminal or: autoload -Uz compinit && compinit
```

## 🎮 Usage

### Interactive Mode

Run the tool with root privileges for interactive menu:

```bash
sudo xdns
```

### Command-Line Options

```bash
# Show help
sudo xdns --help

# Show version
sudo xdns --version

# List available DNS providers
sudo xdns --list

# Set DNS provider by number (1-7)
sudo xdns -s 2              # Set Cloudflare
sudo xdns -s 1 --lock       # Set Google DNS and lock

# Set custom DNS
sudo xdns --custom

# Run speed test
sudo xdns --test

# Restore original configuration
sudo xdns --restore
```

### Interactive Menu
```text
  1. Google DNS (Standard)
  2. Cloudflare (Fast & Private)
  3. Cloudflare (Malware Block)
  4. Quad9 (Security & Privacy)
  5. AdGuard (Ad Blocking)
  6. OpenDNS (Home)
  7. Verisign (Stability)

  C. Custom DNS
  T. Speed Test (Benchmark)
  R. Restore Original
  Q. Keluar
```

### ⚠️ Important Usage Notes

*   **Captive Portals (Public WiFi):** If you are connecting to a public WiFi (Hotel, Airport, Cafe) that requires a login page, **use the Restore (R)** option. Locking a custom DNS often prevents the login page from loading.
*   **VPN Users:** If you use a corporate VPN that relies on internal domain names (Split DNS), strict DNS locking might prevent access to internal servers.

## 🔧 Technical Details

**xdns** is built to be "Distro Agnostic". It works seamlessly on:
*   Debian / Ubuntu / Kali / Mint
*   RHEL / Fedora / CentOS / Rocky
*   Arch Linux / Manjaro / EndeavourOS
*   Alpine Linux
*   OpenSUSE / SLES
*   **Gentoo** *(new in v3.3.0)*
*   **Void Linux** *(new in v3.3.0)*
*   **Solus** *(new in v3.3.0)*

It intelligently handles the differences in how these systems manage DNS caching, file attributes, and network services (NetworkManager, systemd-networkd, ConnMan).

### Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Not running as root |
| 3 | Missing dependencies |
| 4 | Network error |

## 🤝 Contributing

Contributions are welcome! Please ensure any Pull Request maintains the strict safety standards (e.g., no writing to system files without verification).

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

