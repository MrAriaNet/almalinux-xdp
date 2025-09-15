# AlmaLinux XDP Installer & Manager — Technical README

**Safe XDP installer and manager for AlmaLinux systems.**

This project automates the installation of `xdp-tools` and dependencies, detects the primary network interface, loads a default XDP program (`xdp_pass`) safely, and provides automatic fallback if connectivity is lost. Includes an uninstaller and optional systemd service for boot-time loading.

---

## Table of Contents

* [Quickstart](#quickstart)
* [Files](#files)
* [Technical Background](#technical-background)
* [Kernel & Tool Prerequisites](#kernel--tool-prerequisites)
* [How Scripts Work](#how-scripts-work)
* [Systemd Strategy](#systemd-strategy)
* [Loading & Troubleshooting](#loading--troubleshooting)
* [Advanced Usage](#advanced-usage)
* [Measuring Impact](#measuring-impact)
* [Uninstallation & Rollback](#uninstallation--rollback)
* [Security Considerations](#security-considerations)
* [References](#references)

---

## Quickstart

```bash
git clone https://github.com/MrAriaNet/almalinux-xdp.git
cd almalinux-xdp
chmod +x install_xdp.sh uninstall_xdp.sh
./install_xdp.sh [<interface>]
```

* The installer auto-detects the first non-loopback interface if none is provided.
* Press ENTER within 30 seconds to confirm network connectivity or the XDP program will unload automatically.

To uninstall:

```bash
./uninstall_xdp.sh [<interface>]
```

Enable boot-time loading (optional):

```bash
sudo cp xdp-load.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable xdp-load.service
sudo systemctl start xdp-load.service
```

---

## Files

* `install_xdp.sh` — installer and loader (safe mode, detects NIC, loads XDP program).
* `uninstall_xdp.sh` — unloads XDP and cleans up.
* `xdp-load.service` — systemd service to attach XDP at boot.
* `README.md` — technical documentation.
* `LICENSE` — MIT license.
* `CONTRIBUTING.md` — contribution guidelines.

---

## Technical Background

### What is XDP?

XDP (eXpress Data Path) allows eBPF programs to execute at the earliest point in the kernel networking stack. It's used for high-performance packet processing (filtering, telemetry, DDoS mitigation).

### Attachment Modes

* **Native:** Highest performance, attaches to NIC driver.
* **SKB (generic):** Compatible fallback if driver does not support native.
* **Hardware offload:** Requires NIC support (not included in this installer).

The installer defaults to **SKB** mode for maximum compatibility.

---

## Kernel & Tool Prerequisites

Required kernel config:

```
CONFIG_BPF=y
CONFIG_BPF_SYSCALL=y
CONFIG_NET_XDP=y
CONFIG_XDP_SOCKETS (optional)
CONFIG_BPF_JIT (optional)
```

Dependencies:

```
clang, llvm, bpftool, libbpf/libbpf-devel, git, iproute/iproute-tc, make, gcc
```

Verify interface driver:

```bash
ethtool -i <iface>
```

---

## How Scripts Work

### install_xdp.sh

1. Checks for root and sets `SUDO` wrapper.
2. Detects first non-loopback interface if none specified.
3. Installs development tools and dependencies.
4. Clones `xdp-tools` and builds it.
5. Loads `xdp_pass.o` in SKB mode.
6. Waits 30 seconds for user confirmation; auto-unloads if no confirmation.

### uninstall_xdp.sh

1. Detects interface.
2. Unloads any attached XDP program.
3. Removes `xdp-tools` binaries and source.

---

## Systemd Strategy

Use `xdp-load.service` to attach pre-built XDP programs at boot. Recommended to build `.o` once and only attach via systemd instead of rebuilding at every boot.

---

## Loading & Troubleshooting

Check attachment:

```bash
ip -d link show dev <iface>
bpftool prog show
```

Inspect verifier failures:

```bash
sudo dmesg | tail -n 50
sudo journalctl -k -b | grep -i bpf
```

SELinux temporary workaround:

```bash
sudo setenforce 0
```

---

## Advanced Usage

Compile custom XDP programs:

```bash
clang -O2 -target bpf -c xdp_custom.c -o xdp_custom.o
sudo xdp-loader load -m skb <iface> xdp_custom.o --progsec xdp_custom
```

Pin maps for user-space access if needed.

---

## Measuring Impact

* Test connectivity: ping external IPs.
* Use iperf3 for throughput testing.
* Check `xdp-stats` and interface stats.

---

## Uninstallation & Rollback

Run `./uninstall_xdp.sh` to remove XDP program and binaries. Kernel rollback requires manual management if you installed a custom kernel.

---

## Security Considerations

* Load only trusted `.o` files.
* SKB mode recommended for initial testing.
* Ensure sysctl and SELinux policies allow loading eBPF.

---

## References

* [xdp-tools GitHub](https://github.com/xdp-project/xdp-tools)
* [libbpf GitHub](https://github.com/libbpf/libbpf)
* [Kernel eBPF/XDP documentation](https://www.kernel.org/doc/html/latest/bpf/)
