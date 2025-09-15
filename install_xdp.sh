#!/bin/bash
# AlmaLinux XDP Installer & Loader (Safe Version)
# Author: Aria Jahangiri Far
# Purpose: Install dependencies, build xdp-tools, detect interface, and safely attach XDP program

# Exit on any command failure
set -e

# Define colors for logs
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

log_info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# Root detection / sudo wrapper
if [[ $EUID -ne 0 ]]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Detect first non-loopback active interface
IFACE=${1:-$(ip -o link show up | awk -F': ' '!/lo/{print $2; exit}')}
log_info "Using interface: $IFACE"

# Install development tools and dependencies
$SUDO dnf -y groupinstall "Development Tools"
$SUDO dnf -y install clang llvm bpftool libbpf libbpf-devel git iproute iproute-tc

# Clone and build xdp-tools
if [ ! -d "xdp-tools" ]; then
    git clone https://github.com/xdp-project/xdp-tools.git
fi
cd xdp-tools
make -j$(nproc)
$SUDO make install
cd ..

# Load default xdp_pass program in skb mode with safety fallback
log_info "Loading XDP program on $IFACE in skb mode"
$SUDO xdp-loader load -m skb $IFACE /usr/local/lib/bpf/xdp_pass.o --progsec xdp_pass || {
    log_error "Failed to load XDP. Exiting."
    exit 1
}

# Safety confirmation for network connectivity
log_warn "Press ENTER within 30 seconds to confirm network connectivity or the XDP program will unload"
read -t 30
if [ $? -ne 0 ]; then
    log_warn "No confirmation received. Unloading XDP to prevent network loss."
    $SUDO xdp-loader unload $IFACE
fi

log_info "XDP installation completed successfully"
