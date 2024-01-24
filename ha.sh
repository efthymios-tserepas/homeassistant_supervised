#!/bin/bash

# Check if Home Assistant Supervised is already installed
if [ -d "/usr/share/hassio" ]; then
    echo -e "\e[1;31mHome Assistant Supervised is already installed. Exiting script.\e[0m"
    exit 0
fi

# Check the distributor ID
distributor_id=$(lsb_release -i -s)

# Update package sources
sudo apt update

# Check if a package is installed
function is_package_installed() {
    local package_name="$1"
    dpkg -s "$package_name" 2>/dev/null | grep -q "Status: install ok installed"
}

# Install systemd-resolved only if not installed
if ! is_package_installed "systemd-resolved"; then
    echo -e "\e[1;32mInstalling systemd-resolved...\e[0m"
    sudo apt install "systemd-resolved" -y
fi

# Configure systemd-resolved to use Google DNS servers
echo -e "\e[1;32mConfiguring systemd-resolved to use Google DNS servers...\e[0m"
echo -e "[Resolve]\nDNS=8.8.8.8 8.8.4.4\n" | sudo tee /etc/systemd/resolved.conf > /dev/null

# Restart systemd-resolved for changes to take effect
sudo systemctl restart systemd-resolved

# Wait for a few seconds before testing DNS connectivity
echo -e "\e[1;33mWaiting for systemd-resolved to apply DNS settings...\e[0m"
sleep 5

# Test DNS connectivity
if ping -q -c 1 google.com > /dev/null; then
    echo -e "\e[1;32mDNS test successful. Continuing with the script...\e[0m"
else
    echo -e "\e[1;31mDNS test failed. Exiting the script. Please configure the dns.\e[0m"
    exit 1
fi

# List of packages to install
packages=("apparmor" "cifs-utils" "curl" "dbus" "jq" "libglib2.0-bin" "lsb-release" "network-manager" "nfs-common" "udisks2" "wget" "systemd-journal-remote")

# Update package sources
sudo apt update

# Install only if the package is not installed
for package in "${packages[@]}"; do
    if is_package_installed "$package"; then
        echo -e "\e[1;32m$package is already installed.\e[0m"
    else
        sudo apt install "$package" -y
    fi
done

# Convert distributor_id to lowercase
distributor_id_l=$(lsb_release -i -s | tr '[:upper:]' '[:lower:]')
echo "Distributor ID: $distributor_id"

# Check the codename from lsb_release
codename=$(lsb_release -c -s)
echo "Codename: $codename"

# Convert codename to lowercase
codename_lower=$(echo "$codename" | tr '[:upper:]' '[:lower:]')
echo "Codename in lowercase: $codename_lower"

# Create Docker repository URL
docker_repo_url="https://download.docker.com/linux/$distributor_id_l"
echo "Docker Repository URL: $docker_repo_url"

# Create repository to Apt sources
docker_repo_url2="$docker_repo_url"
echo "Apt sources URL: $docker_repo_url2"

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo -e "\e[1;32mDocker is already installed.\e[0m"
else
    case "$distributor_id" in
    "Ubuntu" | "Debian" | "Raspbian")
        echo -e "\e[1;32mDocker is not installed. Installing Docker for $distributor_id...\e[0m"
        ;;
    *)
        echo -e "\e[1;31mDocker is not supported on this system.\e[0m"
        exit 1
        ;;
esac

    # Add Docker's official GPG key
    echo -e "\e[1;32mAdding Docker's official GPG key...\e[0m"
    sudo apt install ca-certificates curl gnupg -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL "$docker_repo_url/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo -e "\e[1;32mDocker's official GPG key added successfully.\e[0m"

# Add the repository to Apt sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] $docker_repo_url $codename_lower stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update packages
    sudo apt update

    # Install Docker packages
    if sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y; then
        # Installation successful
        # Add user to Docker group
        sudo usermod -aG docker $(logname)

        # Enable Docker services
        sudo systemctl enable docker.service
        sudo systemctl enable containerd.service

        echo -e "\e[1;32mDocker has been installed for $distributor_id.\e[0m"

    else
        # Installation failed
        echo -e "\e[1;31mError: Docker installation failed. Please check the logs for more information.\e[0m"
        exit 1
    fi
fi

# Check if the system is Debian 12 (bookworm)
if [ "$distributor_id" = "Debian" ] && [ "$codename_lower" = "bookworm" ]; then
    echo -e "\e[1;32mDebian 12 detected. Installing specific Docker version...\e[0m"
    sudo apt install -y --allow-downgrades docker-ce=5:24.0.7-1~debian.12~bookworm
fi

# Check if user is already in the Docker group
if getent group docker | grep &>/dev/null "\b$(logname)\b"; then
    echo -e "\e[1;32mUser $(logname) is already in the Docker group.\e[0m"
else
    # Add user to Docker group
    sudo usermod -aG docker $(logname)
    echo -e "\e[1;32mUser $(logname) added to the Docker group.\e[0m"
fi

# Determine system architecture
ARCHITECTURE=$(dpkg --print-architecture)

# Convert "amd64" to "x86_64" | "armhf" to "armv7" | "arm64" to "aarch64"
case $ARCHITECTURE in
    amd64) ARCHITECTURE="x86_64" ;;
    armhf) ARCHITECTURE="armv7" ;;
    arm64) ARCHITECTURE="aarch64" ;;
    *) echo "Unsupported architecture: $ARCHITECTURE" ; exit 1 ;;
esac

# Get the latest release URL
RELEASES_URL="https://api.github.com/repos/home-assistant/os-agent/releases/latest"
LATEST_RELEASE=$(curl -s "$RELEASES_URL" | jq -r '.assets[] | select(.name | endswith("'"_$ARCHITECTURE.deb"'")) | .browser_download_url')

if [ -z "$LATEST_RELEASE" ]; then
    echo "Failed to fetch the latest release URL for os-agent_$ARCHITECTURE.deb"
    exit 1
fi

# Extract package name from URL
PACKAGE_NAME=$(basename "$LATEST_RELEASE")

# Print package name
echo -e "\e[1;32mPackage Name: $PACKAGE_NAME\e[0m"

# Download the latest Home Assistant OS Agent
echo -e "\e[1;32mDownloading the latest Home Assistant OS Agent...\e[0m"
wget -O "$PACKAGE_NAME" "$LATEST_RELEASE"

# Install Home Assistant OS Agent
echo -e "\e[1;32mInstalling Home Assistant OS Agent...\e[0m"
sudo dpkg -i $PACKAGE_NAME

# Download Home Assistant Supervised
echo -e "\e[1;32mDownloading Home Assistant Supervised...\e[0m"
wget -O homeassistant-supervised.deb https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb

# Install Home Assistant Supervised
echo -e "\e[1;32mInstalling Home Assistant Supervised...\e[0m"
sudo BYPASS_OS_CHECK=true dpkg -i --ignore-depends=systemd-resolved ./homeassistant-supervised.deb

# Set the initial delay time
initial_delay=300  # 5 minutes in seconds

# Countdown loop with parallel execution of docker check
while [ $initial_delay -gt 0 ]; do
    minutes=$(($initial_delay / 60))
    seconds=$(($initial_delay % 60))
    
    echo -ne "\e[1;33mWaiting for $minutes:$seconds minutes to check the installation of Home Assistant...\e[0m\r"
    
    # Check if any container with "hassio" in the name is running
    if sudo docker ps --format '{{.Names}}' | grep -q "hassio"; then
        echo -e "\e[1;32mA Hassio-related container is running.\e[0m"
        break
    fi
    
    sleep 1
    ((initial_delay--))
done

# If no Hassio-related container is running, perform system reboot
if [ $initial_delay -eq 0 ]; then
    echo -e "\e[1;31mNo Hassio-related container is running. Performing system reboot...\e[0m"
    sudo reboot
fi

# Check if the directory exists and recreate it if needed
if [ -d "/usr/share/hassio/tmp/homeassistant_pulse" ]; then
    echo -e "\e[1;32mDirectory /usr/share/hassio/tmp/homeassistant_pulse already exists.\e[0m"
else
    echo -e "\e[1;31mDirectory /usr/share/hassio/tmp/homeassistant_pulse does not exist. Recreating...\e[0m"
    sudo mkdir -p /usr/share/hassio/tmp/homeassistant_pulse
fi


# Clean up downloaded files
echo "Cleaning up downloaded files..."
rm -f "$PACKAGE_NAME" "./homeassistant-supervised.deb"

echo -e "\e[1;33mHome Assistant installation completed successfully!\e[0m\n"
echo -e "\e[1;32mOpen the link: \e[0m\e[1;92mhttp://$(hostname -I | cut -d' ' -f1):8123\e[0m\n"
echo -e "\e[1;31mIf you see 'This site can’t be reached,' please check again after 5 minutes.\e[0m\n"


