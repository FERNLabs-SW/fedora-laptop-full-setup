# Fedora Laptop Full Setup

**Author:** Rich @ FERNLabs-SW  
**Date:** 2025-11-17  
**Platform:** Fedora Linux (tested on Fedora 43)

---

## Overview

This repository contains a fully automated script for setting up a Fedora laptop with:

- NVIDIA & Intel hybrid graphics (Optimus / PRIME offload)
- Intel CPU microcode and Mesa/Vulkan drivers
- Bluetooth and audio (PipeWire aware)
- NVMe/SMART monitoring tools
- Power and thermal management utilities
- GPU monitoring and auto-switcher services
- System tweaks for performance, battery life, and stability

> Note: This script is designed for personal laptops and is optimized for the following hardware:  
> - CPU: 13th Gen Intel Core i7-13700H  
> - GPU: NVIDIA GeForce RTX 4070 Laptop GPU + Intel Iris Xe  
> - Motherboard: MSI MS-17L5  
> - RAM: 64GB  
> - Storage: NVMe SSD

---

## Features

- **Automated installation** of drivers, firmware, and system utilities  
- **GPU PRIME offload & auto-switching** for battery efficiency  
- **Thermal and power management** (TLP, thermald, powertop)  
- **Monitoring tools** (htop, nvtop, lm_sensors)  
- **System tweaks** for swappiness, inotify limits, and scheduler hints  

---

## Requirements

- Fedora 43 or later  
- Internet connection for package repositories  
- `sudo` privileges  
- SSH key configured for GitHub if using repository cloning

---

## Installation

1. Clone the repository:

```bash
git clone git@github.com:FERNLabs-SW/fedora-laptop-full-setup.git
cd fedora-laptop-full-setup
```
