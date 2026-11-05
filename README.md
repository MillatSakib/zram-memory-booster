# ⚡ zram-memory-booster

<p align="center">
  <strong>Automated Linux Memory Optimizer & zRAM Swap Acceleration Tool</strong>
</p>

<p align="center">
  <a href="https://github.com/MillatSakib/zram-memory-booster/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://www.kernel.org/"><img src="https://img.shields.io/badge/Linux-Kernel%205.x%2B-orange.svg?logo=linux&logoColor=white" alt="Linux Kernel"></a>
  <a href="https://systemd.io/"><img src="https://img.shields.io/badge/systemd-zram--generator-red.svg?logo=systemd&logoColor=white" alt="systemd"></a>
  <a href="https://facebook.github.io/zstd/"><img src="https://img.shields.io/badge/compression-Zstandard%20(zstd)-green.svg" alt="zstd"></a>
  <a href="https://github.com/MillatSakib/zram-memory-booster/stargazers"><img src="https://img.shields.io/github/stars/MillatSakib/zram-memory-booster?style=flat" alt="GitHub Stars"></a>
</p>

---

## 📌 Overview

**zram-memory-booster** is a lightweight, fully automated shell script designed to maximize available RAM and eliminate disk I/O bottlenecks on Debian/Ubuntu-based Linux distributions. 

By creating a compressed swap block device directly in RAM using **`zstd`** compression and fine-tuning Linux kernel Virtual Memory (`sysctl`) parameters, this tool effectively doubles your usable multitasking memory, prevents Out-Of-Memory (OOM) freezing, and preserves SSD endurance by preventing unnecessary disk thrashing.

---

## 🚀 Key Features

- **⚡ Instant 2x+ Effective RAM**: Dynamically compresses anonymous memory pages into RAM before touching physical storage.
- **🗜️ High-Performance `zstd` Compression**: Ultra-fast compression and decompression with industry-leading compression ratios and minimal CPU overhead.
- **🎯 Intelligent Kernel VM Tuning**:
  - `vm.swappiness = 180`: Actively swaps idle anonymous pages to compressed zRAM, keeping precious filesystem page cache warm.
  - `vm.page-cluster = 0`: Disables sequential read-ahead penalties since RAM is zero-latency random access.
  - `vm.watermark_boost_factor = 0` & `vm.watermark_scale_factor = 125`: Eliminates kswapd memory reclaim jitter and system freezes during memory spikes.
- **🔄 Native Systemd Integration**: Powered by `systemd-zram-generator` for seamless service lifecycle management and automatic initialization upon boot.
- **🛡️ SSD & NVMe Protection**: Drastically reduces write wear cycles on solid-state drives.
- **🪄 Zero Configuration Required**: One single command configures, enables, tunes, and verifies the setup.

---

## 🧠 How It Works

Traditional disk swap writes uncompressed memory pages to slow SSDs or HDDs when memory pressure builds, resulting in high latency, system stutter, and heavy I/O wait times.

With **zram-memory-booster**, an in-memory block device (`/dev/zram0`) acts as a prioritized swap device. Memory is dynamically compressed on-the-fly:

```
[ Application Data in RAM ]
             │
      (Memory Pressure)
             ▼
[ zRAM Controller (zstd) ] ────► Compressed ~2:1 to 3:1 in RAM (Zero Disk I/O)
             │
     (If zRAM fills up)
             ▼
[ Traditional Disk Swap / NVMe / SSD ] (Fallback only if configured)
```

> [!NOTE]
> zRAM only allocates physical RAM as needed. If you have 8GB of RAM, assigning `zram-size = ram` creates an 8GB virtual pool that only consumes actual memory proportional to compressed data stored inside it.

---

## 📋 Compatibility & Requirements

| Requirement | Supported Specification |
| :--- | :--- |
| **Operating System** | Ubuntu (20.04+), Debian (11+), Linux Mint, Pop!_OS, Elementary OS, etc. |
| **Kernel Version** | Linux Kernel 5.4 or newer (with `zram` module support) |
| **Init System** | `systemd` |
| **Privileges** | Root / `sudo` access |

---

## 📦 Quick Installation

### Option 1: Git Clone (Recommended)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MillatSakib/zram-memory-booster.git
   cd zram-memory-booster
   ```

2. **Make the script executable:**
   ```bash
   chmod +x setup-zram.sh
   ```

3. **Run with `sudo`:**
   ```bash
   sudo ./setup-zram.sh
   ```

---

## 🔍 Verification & Monitoring

Once the script completes, verify that zRAM is active and healthy:

### 1. Check zRAM Device Status
```bash
zramctl
```
*Example Output:*
```
NAME       ALGORITHM DISKSIZE  DATA  COMPR  TOTAL STREAMS MOUNTPOINT
/dev/zram0 zstd            8G  1.2G 420.5M 480.2M       8 [SWAP]
```

### 2. Inspect Swap Memory Priority
```bash
swapon --show
```
*Ensure `/dev/zram0` has priority `100` (higher priority than disk swap partitions).*

### 3. Check Overall Free Memory
```bash
free -h
```

---

## ⚙️ Configuration Breakdown

The script applies production-grade configurations across two system files:

### 1. `/etc/systemd/zram-generator.conf`
```ini
[zram0]
zram-size = ram              # Dynamic virtual swap equal to 100% physical RAM
compression-algorithm = zstd  # Highest efficiency & low CPU usage
swap-priority = 100          # Prioritize zRAM over physical disk swap
```

### 2. `/etc/sysctl.d/99-zram.conf`
```ini
# Proactively swap idle anonymous memory into fast zRAM, freeing page cache
vm.swappiness = 180

# Disable page clustering (readahead) since RAM has 0 seek latency
vm.page-cluster = 0

# Prevent aggressive memory reclaim latency spikes
vm.watermark_boost_factor = 0
vm.watermark_scale_factor = 125
```

---

## 🧹 Uninstallation / Revert

If you ever wish to remove zRAM and restore standard system defaults:

```bash
# 1. Turn off zram swap
sudo swapoff /dev/zram0 2>/dev/null || true

# 2. Remove configuration files
sudo rm -f /etc/systemd/zram-generator.conf
sudo rm -f /etc/sysctl.d/99-zram.conf

# 3. Reload system settings
sudo systemctl daemon-reload
sudo sysctl --system

# 4. (Optional) Remove the generator package
sudo apt-get remove --purge -y systemd-zram-generator
```

---

## ❓ Frequently Asked Questions (FAQ)

<details>
<summary><strong>Does zRAM steal all my physical RAM upon activation?</strong></summary>
<br>
No! zRAM is dynamically allocated. Even if you assign 100% of your RAM size, it occupies 0 bytes of physical memory until data is actively compressed and written to swap.
</details>

<details>
<summary><strong>Can I keep my existing disk swap or swapfile?</strong></summary>
<br>
Yes. zRAM is configured with a high priority (<code>swap-priority = 100</code>). Linux will automatically write to zRAM first. Only if zRAM becomes completely full will the system overflow into your disk swap.
</details>

<details>
<summary><strong>Why is swappiness set to 180? Isn't that too high?</strong></summary>
<br>
In traditional disk swap, a high swappiness causes disk thrashing. However, with zRAM, swapping anonymous memory is nearly as fast as regular RAM access and preserves fast file cache (VFS). Modern Linux distributions (such as Fedora and Pop!_OS) recommend <code>vm.swappiness = 180</code> for zRAM.
</details>

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check the [issues page](https://github.com/MillatSakib/zram-memory-booster/issues).

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the **MIT License**. See `LICENSE` for more information.

---

<p align="center">
  Crafted with ❤️ by <a href="https://github.com/MillatSakib">Millat Sakib</a>
</p>
