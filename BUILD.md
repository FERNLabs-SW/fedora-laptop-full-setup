
# BUILD Script

---

This guide explains how to make a buildable package from the repository so it can be run as a
one-click install script.

---

## Requirements

- Fedora 43+
- `bash`, `chmod`, `git`
- Root/sudo access

## Steps

1. Clone the repository:
```bash
git clone git@github.com:FERNLabs-SW/fedora-laptop-full-setup.git
cd fedora-laptop-full-setup
```
2. Make the main script executable:
```bash
chmod +x fedora-laptop-full-setup.sh
```
3. Optionally, include helper scripts (GPU check, run-on-nvidia):
```bash
chmod +x run-on-nvidia.sh check_gpu.sh
```
4. Create a simple .tar.gz package for distribution:
```bash
tar -czvf fedora-laptop-setup.tar.gz *.sh *.md
```
5. Users can extract and run:
```bash
tar -xzvf fedora-laptop-setup.tar.gz
./fedora-laptop-full-setup.sh
```
6. Future automation can include adding .desktop file for GUI launch or systemd integration.


---

## Notes
- This package includes all drivers, monitoring tools, and system tweaks.
- Battery optimization and NVIDIA PRIME GPU switching are preconfigured.

---
