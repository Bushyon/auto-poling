# Auto-Poling

Auto-Poling is a script designed for Linux to automatically adjust the polling rate of your mouse whenever a game on Steam is launched. A lower poling rate ouside games should help improving batery life. Tested on Logitech G305, fell free to tell me how te code runs in another devices.

## Installation

To install Auto-Poling, follow these steps:

1. Clone this repository to your local machine.
2. Ensure you have the required dependencies installed (`ratbagctl`).
3. Run the installation script:

```bash
./install.sh
```

## Usage

Once installed, Auto-Poling will monitor Steam game launches and dynamically adjust the polling rate of your mouse accordingly. You can customize the behavior by modifying the script or using command-line parameters.

### Command-line Parameters

- `--min <min_polling_rate>`: Set the minimum polling rate.
- `--max <max_polling_rate>`: Set the maximum polling rate.
- `--update <update_interval>`: Set the update interval in seconds.

## Uninstallation

To uninstall Auto-Poling, run the uninstallation script:

```bash
./uninstall.sh
```

This will remove the service and related files from your system.

## Contributing

If you'd like to contribute to this project, please fork the repository and create a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
