# Auto-Poling

Auto-Poling is a small Linux service that keeps your mouse polling rate low on the desktop and automatically boosts it whenever a game is running. It was built for Steam, but any launcher or standalone binary can be detected through simple process matchers.

## Features
- Watches for Steam games by inspecting running processes for `SteamGameId` / `SteamAppId`.
- Detects Minecraft (official launcher, PrismLauncher, MultiMC, ATLauncher, etc.) out of the box.
- Optional matcher list lets you trigger on other launchers (Lutris, Heroic, Wine binaries, etc.).
- User-level systemd service installs with one script and remembers the last applied rate per session.
- Configuration lives in `.env`, but every value can be overridden via CLI flags (`--min`, `--max`, `--update`).

## Requirements
- Linux with `systemd --user` support.
- `ratbagctl` (from libratbag) with a compatible mouse.
- Permission to read `/proc/$pid/environ` for your user processes (default on most distros).

## Installation
1. Clone the repo and `cd auto-poling`.
2. Edit `.env` (or export overrides) to set your preferred defaults.
3. Run `./install.sh`.

The install script copies a user service into `~/.config/systemd/user/auto-poling.service`, reloads the daemon, and starts it immediately.

## Configuration
All defaults live in `.env`. Edit the file (or provide overrides in your environment) before running `install.sh`.

| Variable | Description |
| --- | --- |
| `MIN_POLLING_RATE` / `MAX_POLLING_RATE` | Rates applied when idle vs. gaming. |
| `UPDATE_INTERVAL` | Seconds between device/process checks. |
| `POLLING_FILE_PATH` | Where the current rate is cached (avoids redundant writes). |
| `SERVICE_NAME` | systemd unit name, if you need multiple instances. |
| `GAME_MATCHERS` | Comma-separated substrings to match against process command lines for non-Steam titles. |
| `MINECRAFT_MATCHERS` | Patterns used to spot Minecraft launchers/clients (defaults cover the official launcher, `.minecraft` paths, PrismLauncher, MultiMC, ATLauncher). |

CLI flags still win over anything defined in `.env`.

## Usage
- To check the service: `systemctl --user status auto-poling`
- To view logs: `journalctl --user-unit=auto-poling -f`
- To run ad-hoc (foreground): `./auto-poling.sh --min 125 --max 1000 --update 15`

When a rate change happens you will see logs like `Polling rate set to 500 (Steam GameID 123456 process detected …)` or `Polling rate set to 125 (No game processes detected)`.

## Uninstallation
```bash
./uninstall.sh
```
That stops the service, disables it, removes the unit file, and reloads the user daemon.

## Tested Devices
- Logitech G305
- Logitech G Pro X Superlight (1st gen)

Any mouse supported by libratbag should behave the same way, since the scripts rely solely on `ratbagctl` for device interaction.

## Troubleshooting
- Ensure `ratbagctl list` shows your mouse and `ratbagctl <device> rate set 500` works manually.
- If no games are detected, confirm the process name appears in `ps -u $USER -f` and add it to `GAME_MATCHERS`.
- Use `journalctl --user-unit=auto-poling -f` to watch detection logs in real time.

## License
[MIT](LICENSE)
