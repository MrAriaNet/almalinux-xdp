#!/bin/bash
# AlmaLinux XDP Uninstaller — Safely unloads XDP and removes tools

set -e

RED="\e[31m"
GREEN="\e[32m"
RESET="\e[0m"
log_info()  { echo -e "${GREEN}[INFO]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

if [[ $EUID -ne 0 ]]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Detect first non-loopback active interface
IFACE=${1:-$(ip -o link show up | awk -F': ' '!/lo/{print $2; exit}')}
log_info "Unloading XDP from interface: $IFACE"
$SUDO xdp-loader unload $IFACE || log_warn "No XDP program attached or failed to unload"

# Remove xdp-tools binaries
log_info "Removing xdp-tools binaries and source"
$SUDO rm -rf /usr/local/lib/bpf/*
$SUDO rm -rf xdp-tools

log_info "XDP uninstallation completed"
