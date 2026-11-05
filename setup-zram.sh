#!/usr/bin/env bash
set -e

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Ei script-ti chalate sudo ba root privilege lagbe."
  echo "Doya kore eivabe run korun: sudo bash $0"
  exit 1
fi

echo "=========================================="
echo "    zram Setup & Optimization Script      "
echo "=========================================="

echo "[1/5] Kernel module zram load kora hocche..."
modprobe zram

echo "[2/5] systemd-zram-generator install kora hocche..."
apt-get update -qq
apt-get install -y -qq systemd-zram-generator

echo "[3/5] /etc/systemd/zram-generator.conf configure kora hocche..."
cat << 'EOF' > /etc/systemd/zram-generator.conf
[zram0]
# Allocate 100% of RAM size as zram compressed swap
# (Physical RAM shudhu tokhoni use hobe jokhon data compress kore swap kora hobe)
zram-size = ram
compression-algorithm = zstd
swap-priority = 100
EOF

echo "[4/5] Kernel VM / Swappiness tune kora hocche (/etc/sysctl.d/99-zram.conf)..."
cat << 'EOF' > /etc/sysctl.d/99-zram.conf
# zram er jonno aggressive swap on anon memory jate file cache thik thake
vm.swappiness = 180
# RAM latency komate single-page swap read/write
vm.page-cluster = 0
# Watermark spike bondho kora
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
EOF

sysctl -p /etc/sysctl.d/99-zram.conf > /dev/null

echo "[5/5] systemd reload ebong zram swap active kora hocche..."
systemctl daemon-reload
systemctl start systemd-zram-setup@zram0.service || true
systemctl start dev-zram0.swap || systemctl start /dev/zram0 || swapon /dev/zram0

echo ""
echo "=========================================="
echo "           zram Setup Complete!           "
echo "=========================================="
echo ""
echo "--- zram status: ---"
zramctl
echo ""
echo "--- Memory & Swap status: ---"
free -h
