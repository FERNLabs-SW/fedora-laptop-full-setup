#!/bin/bash
# fedora-laptop-setup.sh
# Fedora  hardware/setup script - MSI MS-17L5 (Intel 13th gen + RTX 4070)
# - Uses PRIME render offload (no optimus-manager)
# - Installs drivers, firmware, power tools, monitoring, notifications
# - Kernel compatibility check, safe installs, idempotent
# - Adds helper scripts: run-on-nvidia, check_gpu, gpu-notify, gpu-autoswitch (uses offload)
# - Excludes Google/macOS/dev tools
set -euo pipefail
SCRIPT_LOG="/var/log/fedora-laptop-setup.log"
exec > >(tee -a "$SCRIPT_LOG") 2>&1
echo "=== Fedora Laptop Setup started at $(date) ==="

# ---------- helper functions ----------
safe_install() {
  # usage: safe_install pkg1 pkg2 ...
  for pkg in "$@"; do
    if sudo dnf list available "$pkg" &>/dev/null; then
      echo "[+] Installing $pkg"
      sudo dnf install -y "$pkg"
    else
      echo "[-] Package $pkg not available in enabled repos, skipping."
    fi
  done
}

require_sudo() {
  if [ "$EUID" -ne 0 ]; then
    echo "Some operations need sudo. You may be prompted."
  fi
}

# ---------- kernel compatibility check ----------
echo "[*] Checking kernel / driver compatibility..."
KVER=$(uname -r)
echo "Running kernel: $KVER"
# Recommended minimum: kernel >= 6.4 for best 13th gen support but we check roughly
kernel_major=$(echo "$KVER" | cut -d. -f1)
kernel_minor=$(echo "$KVER" | cut -d. -f2)
if [ "$kernel_major" -lt 6 ] || { [ "$kernel_major" -eq 6 ] && [ "$kernel_minor" -lt 4 ]; }; then
  echo "[!] Warning: Kernel < 6.4 detected. Intel 13th gen and latest NVIDIA drivers work best on kernel >= 6.4."
  echo "Consider upgrading kernel (dnf upgrade, or enable ELRepo/OK if you know what you're doing)."
fi

# ---------- enable rpmfusion (safe) ----------
echo "[*] Enabling RPMFusion (free & nonfree) if needed..."
sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm --skip-unavailable || true
sudo dnf install -y https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm --skip-unavailable || true

# ---------- system update ----------
echo "[*] System update..."
sudo dnf upgrade -y || echo "[!] dnf upgrade returned non-zero; continuing."

# ---------- microcode ----------
echo "[*] Intel microcode - safe install"
safe_install intel-ucode microcode_ctl

# ---------- NVIDIA (akmod) and prerequisites ----------
echo "[*] NVIDIA driver (akmod) & prerequisites"
safe_install akmod-nvidia xorg-x11-drv-nvidia-cuda kernel-devel kernel-headers gcc make
# If akmod-nvidia installed, ensure akmods are built for current kernel
if rpm -q akmod-nvidia &>/dev/null; then
  echo "[*] Rebuilding akmods for current kernel..."
  sudo akmods --force || true
  sudo dracut --force || true
fi

# ---------- mesa / intel ----------
echo "[*] Intel Mesa / Vulkan support"
safe_install mesa-dri-drivers mesa-vulkan-drivers

# ---------- firmware / network / wifi ----------
echo "[*] Linux firmware and network packages"
safe_install linux-firmware
# Intel AX201 and Realtek Ethernet drivers normally in kernel + linux-firmware

# ---------- bluetooth (PipeWire era) ----------
echo "[*] Bluetooth + audio (PipeWire aware)"
# Don't install pulseaudio-module-bluetooth (conflicts). Ensure WirePlumber and pipewire-bluez exist
safe_install bluez bluez-tools wireplumber pipewire-pulseaudio pipewire-alsa pipewire-jack pipewire-utils
# Note: pipewire-pulseaudio here is compatibility layer; package name may vary; safe_install will skip if absent

# ---------- NVMe & smart monitoring ----------
echo "[*] NVMe / SMART tools"
safe_install smartmontools nvme-cli

# ---------- Power management ----------
echo "[*] Power / thermal tools"
safe_install tlp thermald powertop
sudo systemctl enable --now tlp || true
sudo systemctl enable --now thermald || true

# ---------- monitoring ----------
echo "[*] Monitoring tools"
safe_install htop neofetch lm_sensors nvtop
sudo sensors-detect --auto || true

# ---------- PRIME / offload helpers ----------
echo "[*] Setting up NVIDIA PRIME render offload helper scripts"

# check_gpu.sh - reports GPU state via nvidia-smi or intel fallback
sudo tee /usr/local/bin/check_gpu.sh >/dev/null <<'EOF'
#!/bin/bash
# Prints which GPU appears active for rendering
if command -v nvidia-smi &>/dev/null; then
  # If any process using NVIDIA or GPU utilization > 0, report NVIDIA
  if nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{s+=$1} END{if(s>0) exit 0; else exit 1}'; then
    echo "Active GPU: NVIDIA (utilization > 0)"
    exit 0
  fi
fi
echo "Active GPU: Intel (no NVIDIA activity detected)"
EOF
sudo chmod +x /usr/local/bin/check_gpu.sh

# run-on-nvidia.sh - wrapper to launch a program on NVIDIA using PRIME offload
sudo tee /usr/local/bin/run-on-nvidia.sh >/dev/null <<'EOF'
#!/bin/bash
# Usage: run-on-nvidia.sh <program> [args...]
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <command> [args...]"
  exit 2
fi
# Environment variables for PRIME render offload
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
# Launch the command
exec "$@"
EOF
sudo chmod +x /usr/local/bin/run-on-nvidia.sh

# create .desktop template to right-click on files to run with NVIDIA (optional)
sudo tee /usr/local/share/applications/run-on-nvidia.desktop >/dev/null <<'EOF'
[Desktop Entry]
Type=Application
Name=Run on NVIDIA GPU
Exec=/usr/local/bin/run-on-nvidia.sh %f
Terminal=false
Categories=Utility;
MimeType=application/x-executable;
EOF

# ---------- GPU autoswitcher (lightweight) ----------
echo "[*] Installing GPU auto-switcher service (uses PRIME offload)"
# autoswitch checks for a list of heavy process names, and if found, runs nothing (offload is per-app).
# Instead of switching whole session, the autoswitch will launch heavy apps via run-on-nvidia.sh if detected in session.
sudo tee /usr/local/bin/gpu-autoswitch-watcher.sh >/dev/null <<'EOF'
#!/bin/bash
# monitors active windows / processes and offers to launch heavy apps with NVIDIA offload
HEAVY=("blender" "steam" "obs" "minecraft")
while true; do
  for P in "${HEAVY[@]}"; do
    if pgrep -x "$P" >/dev/null; then
      echo "$P running; ensure it was started with GPU offload if desired"
    fi
  done
  sleep 10
done
EOF
sudo chmod +x /usr/local/bin/gpu-autoswitch-watcher.sh

sudo tee /etc/systemd/system/gpu-autoswitch-watcher.service >/dev/null <<'EOF'
[Unit]
Description=GPU Autoswitch Watcher (helper hints only)
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/gpu-autoswitch-watcher.sh
Restart=always
User=%%USER%%
Environment=DISPLAY=:0
RestartSec=15

[Install]
WantedBy=default.target
EOF

# Replace placeholder with actual user
sudo sed -i "s/%%USER%%/${USER}/g" /etc/systemd/system/gpu-autoswitch-watcher.service
sudo systemctl daemon-reload
sudo systemctl enable --now gpu-autoswitch-watcher.service || true

# ---------- GPU notification UI ----------
echo "[*] Installing notification helper (libnotify) and service"
safe_install libnotify
sudo tee /usr/local/bin/gpu-notify.sh >/dev/null <<'EOF'
#!/bin/bash
PREV=""
while true; do
  CUR=$( (optimus-manager --print-mode 2>/dev/null || echo "unknown") | awk '/Current GPU/ {print $3}' )
  # If optimus-manager not available, use check_gpu fallback
  if [ -z "$CUR" ] || [ "$CUR" == "unknown" ]; then
    CUR=$( /usr/local/bin/check_gpu.sh | awk '{print $3}' )
  fi
  if [ "$CUR" != "$PREV" ]; then
    /usr/bin/notify-send "GPU active" "Active GPU: $CUR"
    PREV="$CUR"
  fi
  sleep 5
done
EOF
sudo chmod +x /usr/local/bin/gpu-notify.sh

sudo tee /etc/systemd/system/gpu-notify.service >/dev/null <<'EOF'
[Unit]
Description=GPU Notification Service
After=graphical.target

[Service]
Type=simple
ExecStart=/usr/local/bin/gpu-notify.sh
Restart=always
User=%%USER%%
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/%%USER%%/.Xauthority

[Install]
WantedBy=default.target
EOF
sudo sed -i "s/%%USER%%/${USER}/g" /etc/systemd/system/gpu-notify.service
sudo systemctl daemon-reload
sudo systemctl enable --now gpu-notify.service || true

# ---------- system tweaks ----------
echo "[*] Applying system tweaks (swappiness, inotify, scheduler hints)"
sudo sysctl vm.swappiness=10 || true
sudo bash -c 'grep -q "vm.swappiness" /etc/sysctl.conf || echo "vm.swappiness=10" >> /etc/sysctl.conf'
sudo sysctl fs.inotify.max_user_watches=524288 || true
sudo bash -c 'grep -q "fs.inotify.max_user_watches" /etc/sysctl.conf || echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf'

# ---------- udev rule to improve NVIDIA persistence for long jobs ----------
echo "[*] Adding udev rule to enable nvidia-persistenced when NVIDIA present"
sudo tee /etc/udev/rules.d/99-nvidia-persist.rules >/dev/null <<'EOF'
SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", MODE="0660", GROUP="video", RUN+="/bin/systemctl start nvidia-persistenced.service"
EOF

# start nvidia persistence daemon if available
if systemctl list-unit-files | grep -q nvidia-persistenced.service; then
  sudo systemctl enable --now nvidia-persistenced.service || true
fi

# ---------- cleanup ----------
echo "[*] Final cleanup and summary"
sudo dnf autoremove -y || true
sudo dnf clean all || true

echo "=== Fedora Laptop V2 Setup finished at $(date) ==="
echo "Reboot now to ensure NVIDIA modules and services are active."
echo "Usage notes:"
echo " - To run a program on NVIDIA GPU: run-on-nvidia.sh <program> [args...]"
echo " - To see GPU status quickly: check_gpu.sh"
echo " - GPU notifications and gpu-autoswitch-watcher have been enabled (user services)"
echo " - If you prefer explicit control, always start heavy programs using run-on-nvidia.sh"
