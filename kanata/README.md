# kanata

Keyboard remapper. Config lives in `.config/kanata/kanata.conf` and is stowed to
`~/.config/kanata` (`stow kanata`).

On macOS, kanata drives a virtual keyboard through the
**Karabiner-DriverKit-VirtualHIDDevice** driver and runs as a root LaunchDaemon
so it starts at boot.

## Critical: driver version must match kanata

pqrs ships **breaking protocol changes between minor versions** of the driver.
kanata only speaks one protocol version, so the installed driver must match what
the kanata release expects. A mismatch fails with the misleading error:

```
failed to open keyboard device(s): Karabiner-VirtualHIDDevice driver is not activated.
```

…even when `systemextensionsctl list` shows the extension as `activated enabled`.

- **kanata 1.11.0  →  Karabiner-DriverKit-VirtualHIDDevice v6.2.0**
- Check kanata's `docs/setup-macos.md` for the version a newer kanata wants.
- The version reported by `systemextensionsctl list` (e.g. `1.8.0`) is the dext's
  internal protocol number, **not** the package version. The real package version
  is the daemon's `CFBundleShortVersionString`:

  ```sh
  defaults read "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/Info.plist" CFBundleShortVersionString
  ```

### Installing / pinning the driver

```sh
# Download the matching version (6.2.0 here) and install:
curl -fL -o ~/Downloads/Karabiner-DriverKit-VirtualHIDDevice-6.2.0.pkg \
  https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v6.2.0/Karabiner-DriverKit-VirtualHIDDevice-6.2.0.pkg

# If a wrong version is already installed, uninstall it first:
sudo "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/scripts/uninstall/deactivate_driver.sh"
sudo "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice/scripts/uninstall/remove_files.sh"

sudo installer -pkg ~/Downloads/Karabiner-DriverKit-VirtualHIDDevice-6.2.0.pkg -target /

# Activate the driver extension:
/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager forceActivate
```

Then approve it: **System Settings > General > Login Items & Extensions >
Driver Extensions** → enable `org.pqrs.Karabiner-DriverKit-VirtualHIDDevice`.

## LaunchDaemon (run kanata as root at boot)

kanata needs **root** (the driver's output socket is in a root-only dir) **and**
Input Monitoring (to capture input). A user LaunchAgent can't do the former, so
it must be a LaunchDaemon.

```sh
sudo ./launchd/install.sh
```

This copies `launchd/com.kanata.plist` to `/Library/LaunchDaemons/`, sets
`root:wheel` / `644`, and bootstraps it. Logs go to `/Library/Logs/Kanata/`.

### First-time Input Monitoring grant (then REBOOT)

Running `sudo kanata` by hand works because it inherits the terminal's Input
Monitoring grant. A standalone daemon has no parent to inherit from, so it fails
with:

```
IOHIDDeviceOpen error: (iokit/common) not permitted
```

Fix:

1. **System Settings > Privacy & Security > Input Monitoring** → `+` →
   add `/opt/homebrew/bin/kanata` (Cmd+Shift+G to type the path) → toggle **ON**.
2. **Reboot.** Daemon TCC grants generally only take effect on a clean boot —
   `launchctl kickstart` is not enough.

> After `brew upgrade kanata` the binary behind `/opt/homebrew/bin/kanata`
> changes, which can reset the Input Monitoring grant. Re-approve and reboot (or
> `sudo launchctl kickstart -k system/com.kanata`) if remapping stops.

## Manage / troubleshoot

```sh
# Status + recent logs
sudo launchctl print system/com.kanata | grep -E 'state|pid'
sudo tail -f /Library/Logs/Kanata/kanata.out.log    # healthy: 'driver connected: true'

# Stop / start / restart
sudo launchctl bootout   system/com.kanata
sudo launchctl bootstrap system /Library/LaunchDaemons/com.kanata.plist
sudo launchctl kickstart -k system/com.kanata
```

Healthy startup in `kanata.out.log`:

```
entering the event loop
driver activated: true
driver version matched: true
Starting kanata proper
driver connected: true
```
