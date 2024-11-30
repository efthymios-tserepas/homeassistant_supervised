# Home Assistant Supervised Installer

Home Assistant is free and open-source software for home automation designed to be an Internet of Things (IoT) ecosystem-independent integration platform and central control system for smart home devices, with a focus on local control and privacy.

This repository contains Bash scripts for installing Home Assistant Supervised on Debian, Ubuntu, Mint, and Raspberry Pi OS (32-bit and 64-bit) systems. Home Assistant Supervised is a version of Home Assistant that runs in a Docker container, providing a more flexible installation option.

## Supported Systems

The scripts have been successfully tested on the following systems:
- Debian
- Ubuntu
- Mint
- Raspberry Pi OS (32-bit and 64-bit)

## Features

- **Home Assistant Supervised:** Deploy Home Assistant Supervised in a Docker container, providing a flexible and manageable home automation platform.
- **Install Necessary Dependencies:** Automates the installation of required packages and libraries to ensure a smooth setup process.
- **Systemd-resolved Handling:** Does not install `systemd-resolved` and ignores its dependency during the installation of Home Assistant Supervised. Home Assistant operates normally without this specific package, and this issue does not create problems in the APT package management system of the operating system.
- **Docker Installation:** Installs Docker, a platform for developing, shipping, and running applications in containers.
    - If Docker is already installed, the script will not perform any installation or make changes to Docker (only if the OS is Debian, it makes a specific installation of `docker-ce`).
    - If the system is Debian 12 (`bookworm`), installs `docker-ce=5:24.0.7-1-debian.12~bookworm` because the newest version has problems with Home Assistant.
- **Automatic Troubleshooting:** Checks for potential dependency issues and attempts to fix them automatically, ensuring a robust installation process.
- **Cross-Platform Compatibility:** Successfully tested on Debian, Ubuntu, Mint, and Raspberry Pi OS (32-bit and 64-bit) systems.

## Installation

Choose the installation instructions based on the version you wish to install.

### **1. Installation Instructions for Latest Release (v1.2)**

**Option 1: Download and Execute in One Command**

Run the following command in your terminal to download and execute the `ha.sh` script:

```bash
sudo bash -c "$(curl -o- https://github.com/efthymios-tserepas/homeassistant_supervised/releases/download/ha_v1.2/ha_v1-2.sh)"

```

## Potential Issues and Solutions

- If you encounter sound issues on Ubuntu after installation, you can resolve them by following these steps:

1. Settings --> Addon's --> ADD-ON-STORE --> Menu (up right) --> Repositories --> https://github.com/OPHoperHPO/hassio-addons (add)

2. Install Alsa & PulseAudio Fix

3. Start and Start on boot

- On a Raspberry Pi with an older version like Raspbian 10, if you encounter audio issues after installation, run the following command:

```bash

sudo bash -c "$(curl -o- https://raw.githubusercontent.com/efthymios-tserepas/homeassistant_supervised/main/stop_hassio_sound.sh)"

```

## Important Note

- This script is intended for systems compatible with Home Assistant Supervised and may not work on all environments.

Feel free to contribute, report issues, or suggest improvements. For more information on Home Assistant, visit [Home Assistant Official Website](https://www.home-assistant.io/).
