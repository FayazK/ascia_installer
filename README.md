# Ascia Frontend Installer for Home Assistant

[![GitHub Release][releases-shield]][releases]
[![License][license-shield]](LICENSE)

## About

This Home Assistant addon installs the Ascia custom Lovelace UI, a modern and customizable interface for Home Assistant with responsive design and enhanced dashboards.

![Ascia UI Screenshot](https://via.placeholder.com/800x450.png?text=Ascia+UI+Screenshot)

## Features

- **Modern UI**: A clean, responsive design that works well on all devices
- **Easy Installation**: One-click installation through the Home Assistant Addon Store
- **Customizable**: Extensive configuration options for personalization
- **Secure**: Makes backups before any changes, with proper error handling
- **Lightweight**: Minimal impact on performance

## Installation

1. Add this repository to your Home Assistant addon store:
   - In Home Assistant, navigate to **Settings** → **Add-ons** → **Add-on Store**
   - Click the menu icon in the top right and select **Repositories**
   - Add `https://github.com/FayazK/ascia_installer`
   - Click **Close**

2. Find the "Ascia Frontend Installer" addon in the addon store
3. Click **Install**
4. Review the configuration options
5. Click **Start**

## Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `repo` | Repository URL for the Ascia UI | `https://github.com/FayazK/ascia_ui.git` |
| `branch` | Branch to use from the repository | `main` |
| `make_backup` | Create backups of existing files | `true` |
| `restart_ha` | Automatically restart Home Assistant after installation | `true` |

## Safety Features

This addon includes several safety features:

- **Automatic Backups**: Creates backups of your configuration before making any changes
- **Repository Validation**: Checks that the source repository is valid before downloading
- **Security Scanning**: Performs basic security checks on downloaded content
- **Proper Error Handling**: Restores from backup if anything goes wrong
- **Detailed Logs**: Provides comprehensive information about each step
- **Documentation**: Creates installation documentation for future reference

## Troubleshooting

If you encounter any issues with this addon:

1. Check the addon logs for detailed error messages
2. Verify that your Home Assistant instance has internet access
3. If a backup was created, you can restore your original configuration from `/config/backups/ascia/`
4. For advanced issues, please open an issue on the [GitHub repository](https://github.com/FayazK/ascia_installer/issues)

## Uninstallation

To uninstall Ascia UI:

1. Remove the `frontend:` and `development_repo:` lines from your `configuration.yaml` file
2. Restart Home Assistant
3. Delete the `/config/custom_frontend` directory

## Changelog

- 0.1.2
  - Added network resilience for environments with connectivity issues
  - Made installer work without jq dependency for maximum compatibility
  - Added fallback package mirrors for better Alpine repository access

- 0.1.1
  - Fixed compatibility issues with Docker base images
  - Removed version pinning to ensure wider compatibility
  - Simplified container configuration for better reliability

- 0.1.0
  - Enhanced security with repository validation and content scanning
  - Added multiple architecture support
  - Improved error handling and recovery
  - Added automatic backup functionality
  - Added detailed documentation and user instructions

- 0.0.1
  - Initial release

## Support

For support, issues, or feature requests, please use the [GitHub issues](https://github.com/FayazK/ascia_installer/issues) page.

## License

MIT License

[releases-shield]: https://img.shields.io/github/release/FayazK/ascia_installer.svg
[releases]: https://github.com/FayazK/ascia_installer/releases
[license-shield]: https://img.shields.io/github/license/FayazK/ascia_installer.svg
