# Auto-Poling

Auto-Poling is a small Linux service that keeps your mouse polling rate low on the desktop and automatically boosts it whenever a game is running. In theory saving batery on the process.

It was built for Steam, but any launcher or standalone binary can be detected through simple process matchers. 
```
  👉 Dropping from 1000 Hz → 125 Hz can result in:
  
  ~+30–50% longer battery life
  
  ~+20–40 extra hours per charge
```
Chat GPT and voices in my head estimates

## Features
- Watches for Steam games by inspecting running processes for `SteamGameId` / `SteamAppId`.
- Generic process matchers let you boost polling for any launcher or binary (Lutris, Heroic, Wine titles, etc.).
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
| `GAME_MATCHERS` | Comma-separated matchers for non-Steam titles. Plain entries perform case-insensitive substring checks on the entire command line; prefix with `cmd:` to compare against the executable/first argument name, or `exe:` to inspect the resolved binary name. |
| `GAME_BLOCKLIST` | Optional comma-separated entries. Plain substrings (case-insensitive) block every match; entries in the form `<matcher>::<substring>` only apply when that specific matcher fired, which helps suppress helper jobs (e.g., `PrismLauncher::bisync`). |

### Matching tips
- The default `.env` ships with sensible matchers for Prism Launcher, the stock Minecraft launcher, MultiMC/Prism/GDLauncher-derived Java entrypoints, and common loaders (Forge, Fabric, Quilt). Adjust `GAME_MATCHERS` if you use something more exotic.
- Prefer `cmd:` prefixes for GUI launchers such as Prism so helper utilities like `watch` or `inotifywait` (which merely mention the launcher path) do not trigger a false positive.
- If you still see flicker, add targeted blocklist rules with the `<matcher>::substring` form—e.g., `cmd:prismlauncher::watch -n 1` keeps your backup scripts from counting as gameplay while still allowing the real launcher to raise the rate instantly.

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
