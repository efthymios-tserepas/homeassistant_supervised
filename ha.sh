#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Define colors
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

# Define symbols
CHECK_MARK="[✔]"
CROSS_MARK="[x]"

# Save the original username
ORIGINAL_USER=$(logname)

# Initialize progress variables
TOTAL_STEPS=15
CURRENT_STEP=0

# Function to display the progress bar
display_progress_bar() {
    PROGRESS=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    BAR_WIDTH=50
    FILLED_WIDTH=$((PROGRESS * BAR_WIDTH / 100))
    EMPTY_WIDTH=$((BAR_WIDTH - FILLED_WIDTH))
    FILLED_BAR=$(printf "%${FILLED_WIDTH}s" | tr ' ' '#')
    EMPTY_BAR=$(printf "%${EMPTY_WIDTH}s" | tr ' ' '.')
    printf "\n${MAGENTA}Progress: [${FILLED_BAR}${EMPTY_BAR}] ${PROGRESS}%%${NC}\n"
}

# Function to update progress
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    display_progress_bar
}

# Function to check for internet connection
check_internet() {
    echo -n "Checking internet connection... "
    if ! ping -c 1 google.com &>/dev/null; then
        echo -e "${RED}${CROSS_MARK} No internet connection. Please check your network settings.${NC}"
        exit 1
    else
        echo -e "${GREEN}${CHECK_MARK} Internet connection is active.${NC}"
    fi
    update_progress
}

# Function to handle script interruption (e.g., Ctrl+C)
trap_ctrlc() {
    echo -e "${RED}\nScript interrupted. Exiting...${NC}"
    exit 1
}
trap 'trap_ctrlc' INT

# Check for sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script with sudo: sudo $0${NC}"
    exit 1
fi
update_progress

# Check if Home Assistant Supervised is already installed
if [ -d "/usr/share/hassio" ]; then
    echo -e "${YELLOW}Home Assistant Supervised is already installed. Exiting script.${NC}"
    exit 0
fi
update_progress

# Check internet connection
check_internet

# Check the distributor ID
distributor_id=$(lsb_release -i -s)

# If distributor_id is LinuxMint, change it to Ubuntu
if [ "$distributor_id" = "Linuxmint" ]; then
    distributor_id="Ubuntu"
fi

echo -e "${BLUE}Distributor ID: $distributor_id${NC}"

# Convert distributor_id to lowercase
distributor_id_l=$(echo "$distributor_id" | tr '[:upper:]' '[:lower:]')

# Check the codename from lsb_release
codename=$(lsb_release -c -s)
codename_lower=$(echo "$codename" | tr '[:upper:]' '[:lower:]')
echo -e "${BLUE}Codename: $codename (lowercase: $codename_lower)${NC}"
update_progress

# Function to check if a package is installed
is_package_installed() {
    local package_name="$1"
    dpkg -s "$package_name" 2>/dev/null | grep -q "Status: install ok installed"
}

# List of packages to install
packages=("apparmor" "cifs-utils" "curl" "dbus" "jq" "libglib2.0-bin" "lsb-release" "network-manager" "nfs-common" "udisks2" "wget" "systemd-journal-remote")

# Update package sources
echo -e "${BLUE}Updating package sources...${NC}"
sudo apt update
echo -e "${GREEN}${CHECK_MARK} Package sources updated.${NC}"
update_progress

# Install packages if they are not already installed
echo -e "${BLUE}Checking and installing required packages...${NC}"
for package in "${packages[@]}"; do
    if is_package_installed "$package"; then
        echo -e "${GREEN}${CHECK_MARK} $package is already installed.${NC}"
    else
        echo -e "${YELLOW}Installing $package...${NC}"
        sudo apt install "$package" -y
        echo -e "${GREEN}${CHECK_MARK} $package installed successfully.${NC}"
    fi
done
update_progress

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo -e "${GREEN}${CHECK_MARK} Docker is already installed.${NC}"
else
    echo -e "${YELLOW}Docker is not installed. Installing Docker for $distributor_id...${NC}"
    case "$distributor_id" in
        "Ubuntu" | "Debian" | "Raspbian")
            ;;
        *)
            echo -e "${RED}${CROSS_MARK} Docker is not supported on this system.${NC}"
            exit 1
            ;;
    esac

    # Add Docker's official GPG key
    echo -e "${BLUE}Adding Docker's official GPG key...${NC}"
    sudo apt install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "https://download.docker.com/linux/$distributor_id_l/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo -e "${GREEN}${CHECK_MARK} Docker's official GPG key added successfully.${NC}"

    # Add the Docker repository to Apt sources
    echo -e "${BLUE}Adding Docker repository to Apt sources...${NC}"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$distributor_id_l $codename_lower stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package sources
    echo -e "${BLUE}Updating package sources...${NC}"
    sudo apt update
    echo -e "${GREEN}${CHECK_MARK} Package sources updated.${NC}"

    # Install Docker packages
    echo -e "${BLUE}Installing Docker packages...${NC}"
    if sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y; then
        echo -e "${GREEN}${CHECK_MARK} Docker installed successfully for $distributor_id.${NC}"
        # Add user to Docker group
        sudo usermod -aG docker "$ORIGINAL_USER"
        # Enable Docker services
        sudo systemctl enable docker.service
        sudo systemctl enable containerd.service
    else
        echo -e "${RED}${CROSS_MARK} Error: Docker installation failed. Please check the logs for more information.${NC}"
        exit 1
    fi
fi
update_progress

# Check if the system is Debian 12 (bookworm)
if [ "$distributor_id" = "Debian" ] && [ "$codename_lower" = "bookworm" ]; then
    echo -e "${BLUE}Debian 12 detected. Installing specific Docker version...${NC}"
    sudo apt install -y --allow-downgrades docker-ce=5:24.0.7-1~debian.12~bookworm
    # Hold the docker-ce package to prevent upgrades
    echo "docker-ce hold" | sudo dpkg --set-selections
    echo -e "${GREEN}${CHECK_MARK} Specific Docker version installed and held.${NC}"
fi
update_progress

# Check if the user is already in the Docker group
if getent group docker | grep &>/dev/null "\b$ORIGINAL_USER\b"; then
    echo -e "${GREEN}${CHECK_MARK} User $ORIGINAL_USER is already in the Docker group.${NC}"
else
    # Add user to Docker group
    sudo usermod -aG docker "$ORIGINAL_USER"
    echo -e "${GREEN}${CHECK_MARK} User $ORIGINAL_USER added to the Docker group.${NC}"
fi
update_progress

# Determine system architecture
ARCHITECTURE=$(dpkg --print-architecture)

# Convert architecture to match Home Assistant OS Agent naming
case $ARCHITECTURE in
    amd64) ARCHITECTURE="x86_64" ;;
    armhf) ARCHITECTURE="armv7" ;;
    arm64) ARCHITECTURE="aarch64" ;;
    *) echo -e "${RED}${CROSS_MARK} Unsupported architecture: $ARCHITECTURE${NC}" ; exit 1 ;;
esac
echo -e "${BLUE}System architecture: $ARCHITECTURE${NC}"
update_progress

# Get the latest release URL for Home Assistant OS Agent
RELEASES_URL="https://api.github.com/repos/home-assistant/os-agent/releases/latest"
LATEST_RELEASE=$(curl -s "$RELEASES_URL" | jq -r '.assets[] | select(.name | endswith("'"_$ARCHITECTURE.deb"'")) | .browser_download_url')

if [ -z "$LATEST_RELEASE" ]; then
    echo -e "${RED}${CROSS_MARK} Failed to fetch the latest release URL for os-agent_$ARCHITECTURE.deb${NC}"
    exit 1
fi

# Extract package name from URL
PACKAGE_NAME=$(basename "$LATEST_RELEASE")
echo -e "${BLUE}Package name: $PACKAGE_NAME${NC}"

# Download the latest Home Assistant OS Agent
echo -e "${BLUE}Downloading the latest Home Assistant OS Agent...${NC}"
wget -O "$PACKAGE_NAME" "$LATEST_RELEASE"
echo -e "${GREEN}${CHECK_MARK} Home Assistant OS Agent downloaded successfully.${NC}"
update_progress

# Install Home Assistant OS Agent
echo -e "${BLUE}Installing Home Assistant OS Agent...${NC}"
sudo dpkg -i $PACKAGE_NAME
echo -e "${GREEN}${CHECK_MARK} Home Assistant OS Agent installed successfully.${NC}"
update_progress

# Download Home Assistant Supervised
echo -e "${BLUE}Downloading Home Assistant Supervised...${NC}"
wget -O homeassistant-supervised.deb https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb
echo -e "${GREEN}${CHECK_MARK} Home Assistant Supervised downloaded successfully.${NC}"
update_progress

# Extract control.tar.xz
echo -e "${BLUE}Extracting control.tar.xz...${NC}"
sudo ar x homeassistant-supervised.deb
sudo tar xf control.tar.xz
echo -e "${GREEN}${CHECK_MARK} control.tar.xz extracted successfully.${NC}"
update_progress

# Edit control file to remove systemd-resolved dependency
echo -e "${BLUE}Editing control file to remove systemd-resolved dependency...${NC}"
sed -i '/Depends:.*systemd-resolved/d' control
echo -e "${GREEN}${CHECK_MARK} systemd-resolved dependency removed.${NC}"
update_progress

# Recreate control.tar.xz
echo -e "${BLUE}Recreating control.tar.xz...${NC}"
sudo tar cfJ control.tar.xz postrm postinst preinst control templates
echo -e "${GREEN}${CHECK_MARK} control.tar.xz recreated successfully.${NC}"
update_progress

# Recreate the .deb package
echo -e "${BLUE}Recreating the .deb package...${NC}"
sudo ar rcs homeassistant-supervised.deb debian-binary control.tar.xz data.tar.xz
echo -e "${GREEN}${CHECK_MARK} .deb package recreated successfully.${NC}"
update_progress

# Install Home Assistant Supervised
echo -e "${BLUE}Installing Home Assistant Supervised...${NC}"
sudo BYPASS_OS_CHECK=true dpkg -i ./homeassistant-supervised.deb
echo -e "${GREEN}${CHECK_MARK} Home Assistant Supervised installed successfully.${NC}"
update_progress

# Set the initial delay time
initial_delay=300  # 5 minutes in seconds

# Countdown loop with parallel execution of docker check
while [ $initial_delay -gt 0 ]; do
    minutes=$(($initial_delay / 60))
    seconds=$(($initial_delay % 60))
    
    echo -ne "${YELLOW}Waiting for $minutes:$seconds minutes to check the installation of Home Assistant...${NC}\r"
    
    # Check if any container with "hassio" in the name is running
    if sudo docker ps --format '{{.Names}}' | grep -q "hassio"; then
        echo -e "\n${GREEN}${CHECK_MARK} A Hassio-related container is running.${NC}"
        break
    fi
    
    sleep 1
    ((initial_delay--))
done

# If no Hassio-related container is running, perform system reboot
if [ $initial_delay -eq 0 ]; then
    echo -e "${RED}${CROSS_MARK} No Hassio-related container is running. Performing system reboot...${NC}"
    sudo reboot
fi
update_progress

# Check if the directory exists and recreate it if needed
if [ -d "/usr/share/hassio/tmp/homeassistant_pulse" ]; then
    echo -e "${GREEN}${CHECK_MARK} Directory /usr/share/hassio/tmp/homeassistant_pulse already exists.${NC}"
else
    echo -e "${YELLOW}Directory /usr/share/hassio/tmp/homeassistant_pulse does not exist. Creating...${NC}"
    sudo mkdir -p /usr/share/hassio/tmp/homeassistant_pulse
    echo -e "${GREEN}${CHECK_MARK} Directory created successfully.${NC}"
fi
update_progress

# Clean up downloaded files
echo -e "${BLUE}Cleaning up downloaded files...${NC}"
rm -f "$PACKAGE_NAME" "./homeassistant-supervised.deb" "control" "data.tar.xz" "control.tar.xz"
echo -e "${GREEN}${CHECK_MARK} Downloaded files deleted.${NC}"
update_progress

echo -e "${CYAN}\nHome Assistant installation completed successfully!${NC}\n"
echo -e "${BLUE}A system reboot will be performed to apply the changes.${NC}\n"
echo -e "${GREEN}After reboot, open the link: ${NC}${GREEN}http://$(hostname -I | cut -d' ' -f1):8123${NC}\n"
echo -e "${YELLOW}If you see 'This site can’t be reached,' please check again after 5 minutes.${NC}\n"

# Reboot system
sudo reboot
