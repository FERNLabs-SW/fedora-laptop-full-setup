# Fedora Laptop Full Setup Script

A fully automated Fedora setup script designed for high-performance laptops, including hybrid graphics (Intel + NVIDIA), gaming laptops, and developer machines.

This project was created for a **13th Gen Intel (i7-13700H) + NVIDIA RTX 4070** laptop, but supports any modern Fedora machine.

The script includes:
- Automated CPU/GPU driver installation
- Optimus hybrid switching (Intel for battery, NVIDIA for performance)
- Network, Wi-Fi, and Bluetooth firmware
- ALSA/PipeWire audio fixes
- System stability tweaks
- Optional extra tools and monitoring utilities
- Battery-friendly defaults
- A fully automated installer

No Google products are installed.  
No development tools, IDEs, or macOS theming are included (those have separate scripts).

---


## 🔧 Features


- Automatically installs all required drivers:
  - NVIDIA 580 drivers (akmod)
  - Intel Iris Xe graphics drivers (Mesa)
  - Intel CPU microcode
- Ensures proper hybrid GPU switching
- Installs useful system utilities:
  - `nvtop` (GPU monitor)
  - `powertop` (battery optimization)
  - `lm_sensors` (temperature monitoring)
- Wireless + Bluetooth firmware repair
- PipeWire audio stability fixes
- Laptop performance & power tuning
- Fast, clean, and idempotent (safe to run multiple times)


---


## 🚀 Installation

```bash
curl -LO https://github.com/FERNLabs-SW/fedora-laptop-full-setup/releases/latest/download/fedora-laptop-full-setup.tar.gz
tar -xf fedora-laptop-full-setup.tar.gz
cd fedora-laptop-full-setup
sudo ./install.sh
```

## 🧹 Uninstallation

```bash
sudo ./uninstall.sh
```

## 🗂 Repository Structure
/
├─ fedora-laptop-full-setup.sh     # Main script
├─ install.sh                      # Installer wrapper
├─ uninstall.sh                    # Uninstaller wrapper
├─ scripts/                        # Additional modules
├─ assets/                         # Icons, config templates, etc.
├─ README.md
├─ INSTALL.md
├─ UNINSTALL.md
├─ CONTRIBUTING.md
├─ CHANGELOG.md
└─ LICENSE


## 📦 GitHub Actions (CI/CD)


