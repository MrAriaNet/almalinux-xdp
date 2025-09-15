# AlmaLinux XDP Installer & Manager

**Safe XDP installer for AlmaLinux servers with automatic NIC detection, safety fallback, and optional systemd auto-load.**

## Files
- `install_xdp.sh` — install dependencies, build xdp-tools, attach XDP with safety confirmation.
- `uninstall_xdp.sh` — unloads XDP, removes binaries and source.
- `xdp-load.service` — systemd service for automatic boot loading.
- `README.md` — this document.
- `LICENSE` — MIT license.
- `CONTRIBUTING.md` — contribution guide.

## Quickstart
```bash
git clone https://github.com/MrAriaNet/almalinux-xdp.git
cd almalinux-xdp
chmod +x install_xdp.sh uninstall_xdp.sh
./install_xdp.sh [<iface>]
````

## Auto-start with systemd

```bash
sudo cp xdp-load.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable xdp-load.service
sudo systemctl start xdp-load.service
```

## Technical Notes

* Default mode is `skb` for maximum compatibility.
* Safety timer ensures network connectivity before keeping XDP attached.
* For advanced users, you can compile custom XDP programs and use `xdp-loader`.
