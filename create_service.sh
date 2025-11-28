#!/bin/bash

# Selene AI Assistant - Systemd Service Creator
# This script creates a systemd service to run Selene as a system service

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}📦 Selene - Create Systemd Service${NC}"
echo -e "${BLUE}============================================================${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR] This script must be run as root (use sudo)${NC}"
    exit 1
fi

# Get current directory and user
INSTALL_DIR=$(pwd)
INSTALL_USER=${SUDO_USER:-$USER}

# Validate install directory
if [ ! -f "$INSTALL_DIR/assistant.py" ]; then
    echo -e "${RED}[ERROR] assistant.py not found in current directory${NC}"
    echo -e "${YELLOW}Please run this script from the ai-assistant-env directory${NC}"
    exit 1
fi

echo -e "${YELLOW}Creating systemd service...${NC}"
echo -e "Install directory: ${BLUE}$INSTALL_DIR${NC}"
echo -e "Running as user: ${BLUE}$INSTALL_USER${NC}\n"

# Verify user exists
if ! id "$INSTALL_USER" &>/dev/null; then
    echo -e "${RED}[ERROR] User '$INSTALL_USER' does not exist${NC}"
    exit 1
fi

# Create systemd service file
SERVICE_FILE="/etc/systemd/system/selene.service"

echo -e "${YELLOW}Writing service file to: ${BLUE}$SERVICE_FILE${NC}"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Selene AI Assistant - Fedora Linux Voice Assistant
After=network.target ollama.service
Wants=ollama.service

[Service]
Type=simple
User=$INSTALL_USER
WorkingDirectory=$INSTALL_DIR
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONUNBUFFERED=1"
ExecStart=/usr/bin/python3 $INSTALL_DIR/assistant.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Security settings
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[OK] Service file created successfully${NC}\n"
else
    echo -e "${RED}[ERROR] Failed to create service file${NC}"
    exit 1
fi

# Verify the file was created
if [ ! -f "$SERVICE_FILE" ]; then
    echo -e "${RED}[ERROR] Service file was not created${NC}"
    exit 1
fi

echo -e "${YELLOW}Service file contents:${NC}"
echo -e "${BLUE}---${NC}"
cat "$SERVICE_FILE"
echo -e "${BLUE}---${NC}\n"

# Set proper permissions
chmod 644 "$SERVICE_FILE"
echo -e "${GREEN}[OK] Set service file permissions${NC}\n"

# Reload systemd
echo -e "${YELLOW}Reloading systemd daemon...${NC}"
if systemctl daemon-reload; then
    echo -e "${GREEN}[OK] Systemd daemon reloaded${NC}\n"
else
    echo -e "${RED}[ERROR] Failed to reload systemd daemon${NC}"
    exit 1
fi

# Verify service is recognized
if systemctl list-unit-files | grep -q "selene.service"; then
    echo -e "${GREEN}[OK] Service recognized by systemd${NC}\n"
else
    echo -e "${RED}[ERROR] Service not recognized by systemd${NC}"
    systemctl list-unit-files | grep selene || true
    exit 1
fi

# Instructions
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}✅ Systemd Service Created Successfully!${NC}"
echo -e "${BLUE}============================================================${NC}\n"

echo -e "${YELLOW}Service Management Commands:${NC}"
echo -e "Start the service:     ${BLUE}sudo systemctl start selene${NC}"
echo -e "Stop the service:      ${BLUE}sudo systemctl stop selene${NC}"
echo -e "Restart the service:   ${BLUE}sudo systemctl restart selene${NC}"
echo -e "Enable on boot:        ${BLUE}sudo systemctl enable selene${NC}"
echo -e "Disable on boot:       ${BLUE}sudo systemctl disable selene${NC}"
echo -e "Check status:          ${BLUE}sudo systemctl status selene${NC}"
echo -e "View logs:             ${BLUE}sudo journalctl -u selene -f${NC}\n"

echo -e "${YELLOW}Important Notes:${NC}"
echo -e "1. Make sure Ollama is installed and running"
echo -e "2. The service will run as user: ${BLUE}$INSTALL_USER${NC}"
echo -e "3. Logs are available via journalctl"
echo -e "4. The service will auto-restart if it crashes\n"

# Check if running non-interactively (from master installer)
if [ ! -t 0 ]; then
    # Non-interactive mode - start automatically
    echo -e "${BLUE}Starting service automatically...${NC}\n"
    if systemctl start selene 2>&1; then
        sleep 3
        if systemctl is-active --quiet selene; then
            echo -e "${GREEN}[OK] Service started successfully!${NC}\n"
        else
            echo -e "${RED}[ERROR] Service failed to start${NC}"
            echo -e "${YELLOW}Check logs with: sudo journalctl -u selene -n 50${NC}\n"
        fi
    else
        echo -e "${RED}[ERROR] Failed to start service${NC}\n"
    fi
else
    # Interactive mode - ask user
    read -p "Do you want to start the service now? (y/n) [y]: " -r
    REPLY=${REPLY:-y}
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Starting service...${NC}"
        if systemctl start selene; then
            sleep 3
            echo -e "\n${YELLOW}Checking service status...${NC}"
            systemctl status selene --no-pager -l
            echo
            if systemctl is-active --quiet selene; then
                echo -e "${GREEN}✅ Service is running!${NC}"
                echo -e "Check status with: ${BLUE}sudo systemctl status selene${NC}\n"
            else
                echo -e "${RED}❌ Service failed to start${NC}"
                echo -e "${YELLOW}Check logs with: ${BLUE}sudo journalctl -u selene -n 50${NC}\n"
            fi
        else
            echo -e "\n${RED}[ERROR] Failed to start service${NC}"
            echo -e "${YELLOW}Check logs with: ${BLUE}sudo journalctl -u selene -n 50${NC}\n"
        fi
    fi
fi

echo -e "${GREEN}Done! 🚀${NC}\n"
