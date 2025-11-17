# Fedora Laptop Full Setup

This repository contains an automated setup script for a Fedora laptop tailored for optimal performance and hardware support. It includes GPU switching, Intel/NVIDIA drivers, thermal/power management, and monitoring tools.

---

## Features

- Automatic installation of Intel & NVIDIA drivers
- PRIME GPU offload support
- Power and thermal optimization (TLP, thermald, powertop)
- System monitoring tools (htop, lm_sensors, nvtop)
- Audio/Bluetooth setup with PipeWire
- System tweaks for improved performance (swappiness, inotify, scheduler hints)

---

## Usage

1. Clone the repository:
```bash
git clone git@github.com:FERNLabs-SW/fedora-laptop-full-setup.git
cd fedora-laptop-full-setup
```


2. Make the script executable:
```bash
chmod +x fedora-laptop-full-setup.sh
```


3. Run the setup script:
```bash
./fedora-laptop-full-setup.sh
```


4. **Reboot when finished to ensure all services are active.**


---

# Running Programs on NVIDIA GPU

To run NVIDIA GPU on a certain program:
```bash
run-on-nvidia.sh <program> [args...]
```
Check which GPU is active:
bash
```bash
check_gpu.sh
```

---

FERNLabs SW.

---
