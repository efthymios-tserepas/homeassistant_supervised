# Home Assistant Supervised Installer

This repository contains a Bash script for installing Home Assistant Supervised on Debian, Ubuntu, and Raspberry Pi OS (32-bit and 64-bit) systems. Home Assistant Supervised is a version of Home Assistant that runs in a Docker container, providing a more flexible installation option.

## Supported Systems

The script has been successfully tested on the following systems:
- Debian
- Ubuntu
- Raspberry Pi OS (32-bit and 64-bit)

## Usage

- Ensure that your system meets the requirements mentioned in the script.
- Execute the script to install the necessary dependencies, Docker, and Home Assistant Supervised.
- Download and execute the script by running the following command:

```bash
sudo curl -Lo ha.sh https://raw.githubusercontent.com/efthymios-tserepas/homeassistant_supervised/main/ha.sh && sudo bash ha.sh

## Important Note

- This script is intended for systems compatible with Home Assistant Supervised and may not work on all environments.

Feel free to contribute, report issues, or suggest improvements. For more information on Home Assistant, visit [Home Assistant Official Website](https://www.home-assistant.io/).
