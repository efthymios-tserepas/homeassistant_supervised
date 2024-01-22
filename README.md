# Home Assistant Supervised Installer

This repository contains a Bash script for installing Home Assistant Supervised on Debian, Ubuntu, and Raspberry Pi OS (32-bit and 64-bit) systems. Home Assistant Supervised is a version of Home Assistant that runs in a Docker container, providing a more flexible installation option.

## Supported Systems

The script has been successfully tested on the following systems:
- Debian
- Ubuntu
- Raspberry Pi OS (32-bit and 64-bit)

# Features
- Install the necessary dependencies: The script automates the installation of required packages and libraries to ensure a smooth setup process.

- Docker Installation: The script installs Docker, a platform for developing, shipping, and running applications in containers.

- Home Assistant Supervised: Deploy Home Assistant Supervised in a Docker container, providing a flexible and manageable home automation platform.

- Automatic Troubleshooting: The script checks for potential dependency issues and attempts to fix them automatically, ensuring a robust installation process.

- Cross-Platform Compatibility: Successfully tested on Debian, Ubuntu, and Raspberry Pi OS (32-bit and 64-bit) systems.

## Important Note

- This script is intended for systems compatible with Home Assistant Supervised and may not work on all environments.

Feel free to contribute, report issues, or suggest improvements. For more information on Home Assistant, visit [Home Assistant Official Website](https://www.home-assistant.io/).

## Install

To install Home Assistant Supervised with the default settings, run the following command:

```bash
sudo bash -c "$(curl -o- https://raw.githubusercontent.com/efthymios-tserepas/homeassistant_supervised/main/ha.sh)"
