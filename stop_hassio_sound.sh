#!/bin/bash

# Service file name
SERVICE_FILE="/etc/systemd/system/stop_hassio_audio.service"

# Service file content
SERVICE_CONTENT="[Unit]
Description=Stop hassio_audio container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=true
ExecStart=/bin/bash -c 'sleep 20 && docker stop hassio_audio && docker rm hassio_audio'

[Install]
WantedBy=multi-user.target
"

# Write content to the service file
echo "$SERVICE_CONTENT" | sudo tee "$SERVICE_FILE" > /dev/null

# Update file permissions
sudo chmod 644 "$SERVICE_FILE"

# Verify that the service file was created successfully
if [ -e "$SERVICE_FILE" ]; then
    echo "The service file was created successfully: $SERVICE_FILE"
else
    echo "There was an issue creating the service file."
fi

sudo reboot
