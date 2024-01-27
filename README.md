# Home Assistant Supervised Installer

Home Assistant is free and open-source software for home automation designed to be an Internet of things ecosystem-independent integration platform and central control system for smart home devices, with a focus on local control and privacy.

This repository contains a Bash script for installing Home Assistant Supervised on Debian, Ubuntu, Mint and Raspberry Pi OS (32-bit and 64-bit) systems. Home Assistant Supervised is a version of Home Assistant that runs in a Docker container, providing a more flexible installation option.

## Supported Systems

The script has been successfully tested on the following systems:
- Debian
- Ubuntu
- Mint
- Raspberry Pi OS (32-bit and 64-bit)

# Features
- Home Assistant Supervised: Deploy Home Assistant Supervised in a Docker container, providing a flexible and manageable home automation platform.

- Install the necessary dependencies: The script automates the installation of required packages and libraries to ensure a smooth setup process.

- It does not install systemd-resolved and ignores its dependency during the installation of Home Assistant Supervised. Home Assistant operates normally without this specific package, and this issue does not create problems in the apt package management system of the operating system.

- Docker Installation: The script installs Docker, a platform for developing, shipping, and running applications in containers.

- If Docker is already installed, the script will not perform any installation or make changes to Docker (only if the OS is debian make a specific installation of docker-ce)

- If is debian 12 install the docker-ce=5:24.0.7-1-debian.12-bookworm because the newest has problem with homeassistant.

- Automatic Troubleshooting: The script checks for potential dependency issues and attempts to fix them automatically, ensuring a robust installation process.

- Cross-Platform Compatibility: Successfully tested on Debian, Ubuntu, Mint and Raspberry Pi OS (32-bit and 64-bit) systems.

## Important Note

- This script is intended for systems compatible with Home Assistant Supervised and may not work on all environments.

Feel free to contribute, report issues, or suggest improvements. For more information on Home Assistant, visit [Home Assistant Official Website](https://www.home-assistant.io/).

## Install

To install Home Assistant Supervised with the default settings, run the following command:

```bash

sudo bash -c "$(curl -o- https://raw.githubusercontent.com/efthymios-tserepas/homeassistant_supervised/main/ha.sh)"

