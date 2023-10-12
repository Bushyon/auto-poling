# Auto-Poling

Auto-Poling is a script designed for Linux to automatically adjust the polling rate of your mouse whenever a game on Steam is launched. A lower poling rate ouside games should help improving batery life.

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

## Tested on
Tested on Logitech G305 in archlinux, in theory should work on the Steam Deck / other distros and other mices as well. Fell free to let me know!

## Some Ideas for New Features

1. **Profile Management**: Allow users to set different polling rate profiles for specific games or applications.

2. **Customizable Device IDs**: Let users specify the device IDs for which the polling rate should be adjusted.

3. **Notification System**: Implement an optional notification system to alert users when the polling rate changes.

4. **Logging**: Add a logging feature to keep a record of when and why the polling rate was changed.

5. **GUI Configuration Tool**: Create a simple GUI for users to configure settings without directly editing the script.

6. **Support for Multiple Mice**: Extend the script to work with multiple mice connected to the system.

7. **Game Whitelist/Blacklist**: Allow users to specify a list of games that should always have a certain polling rate.

8. **Integration with Gaming Platforms**: Integrate with platforms beyond Steam.

9. **Multi-Platform Support**: Ensure compatibility with a wider range of Linux distributions.

10. **Low Battery Mode**: Implement a feature that dynamically adjusts the polling rate when a low battery level is detected.

11. **Automatic Updates**: Add a feature to check for and apply updates to the script.

12. **Support for Additional Devices**: Test and ensure compatibility with a broader range of gaming mice models.

13. **Resource Usage**: Ensure the resource impact on the system is minimal, for optimal FPS. 😎

## Contributing

If you'd like to contribute to this project, please fork the repository and create a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
