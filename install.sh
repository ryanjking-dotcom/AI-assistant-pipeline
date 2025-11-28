#!/bin/bash

# Selene AI Assistant - Master Installer
# One script to rule them all - complete automated setup

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Banner
clear
echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║   ███████╗███████╗██╗     ███████╗███╗   ██╗███████╗      ║
║   ██╔════╝██╔════╝██║     ██╔════╝████╗  ██║██╔════╝      ║
║   ███████╗█████╗  ██║     █████╗  ██╔██╗ ██║█████╗        ║
║   ╚════██║██╔══╝  ██║     ██╔══╝  ██║╚██╗██║██╔══╝        ║
║   ███████║███████╗███████╗███████╗██║ ╚████║███████╗      ║
║   ╚══════╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝      ║
║                                                            ║
║          Fedora Linux AI Assistant Installer              ║
║                    Version 1.0.0                           ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

echo -e "${CYAN}🤖 Welcome to the Selene Installation Wizard!${NC}"
echo -e "${YELLOW}This installer will guide you through the complete setup.${NC}\n"

# Check if scripts exist
if [ ! -f "setup.sh" ]; then
    echo -e "${RED}[ERROR] setup.sh not found in current directory${NC}"
    echo -e "${YELLOW}Please run this script from the ai-assistant-env directory${NC}"
    exit 1
fi

# Detect if running with sudo
if [ "$EUID" -eq 0 ]; then
    SUDO_CMD=""
    echo -e "${YELLOW}⚠️  Running as root. Some operations will run without sudo.${NC}\n"
else
    SUDO_CMD="sudo"
fi

# Installation options
INSTALL_NGINX=false
INSTALL_SERVICE=false
DOMAIN_NAME="selene.local"

# Interactive prompts
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Installation Configuration${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"

# Ask about nginx
echo -e "${YELLOW}Would you like to set up nginx reverse proxy?${NC}"
echo -e "${BLUE}  This gives you a clean URL without port numbers${NC}"
echo -e "${BLUE}  Example: http://selene.local instead of http://localhost:5000${NC}"
read -p "$(echo -e ${GREEN}"Install nginx? (y/n) [y]: "${NC})" -n 1 -r NGINX_CHOICE
echo
NGINX_CHOICE=${NGINX_CHOICE:-y}

if [[ $NGINX_CHOICE =~ ^[Yy]$ ]]; then
    INSTALL_NGINX=true
    echo
    echo -e "${YELLOW}What domain name would you like to use?${NC}"
    echo -e "${BLUE}Examples: selene.local, chat.selene, myassistant.local${NC}"
    read -p "$(echo -e ${GREEN}"Domain name [selene.local]: "${NC})" USER_DOMAIN
    DOMAIN_NAME=${USER_DOMAIN:-selene.local}
fi

echo

# Ask about systemd service
echo -e "${YELLOW}Would you like to run Selene as a system service?${NC}"
echo -e "${BLUE}  This makes Selene start automatically on boot${NC}"
echo -e "${BLUE}  Recommended for server deployments${NC}"
read -p "$(echo -e ${GREEN}"Install as service? (y/n) [y]: "${NC})" -n 1 -r SERVICE_CHOICE
echo
SERVICE_CHOICE=${SERVICE_CHOICE:-y}

if [[ $SERVICE_CHOICE =~ ^[Yy]$ ]]; then
    INSTALL_SERVICE=true
fi

# Confirmation
echo
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Installation Summary${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Base Installation:${NC}      ${GREEN}Yes${NC}"
echo -e "${BLUE}  Nginx Reverse Proxy:${NC}   ${GREEN}$([ "$INSTALL_NGINX" = true ] && echo "Yes ($DOMAIN_NAME)" || echo "No")${NC}"
echo -e "${BLUE}  Systemd Service:${NC}       ${GREEN}$([ "$INSTALL_SERVICE" = true ] && echo "Yes" || echo "No")${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"

read -p "$(echo -e ${YELLOW}"Proceed with installation? (y/n) [y]: "${NC})" -n 1 -r CONFIRM
echo
CONFIRM=${CONFIRM:-y}

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation cancelled.${NC}"
    exit 0
fi

echo
echo -e "${GREEN}🚀 Starting installation...${NC}\n"
sleep 2

# Step 1: Base installation
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  Step 1/3: Installing Selene Base System${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"

chmod +x setup.sh

if ./setup.sh --system; then
    echo -e "\n${GREEN}✅ Base installation completed successfully!${NC}\n"
else
    echo -e "\n${RED}❌ Base installation failed!${NC}"
    echo -e "${YELLOW}Please check the error messages above and try again.${NC}"
    exit 1
fi

sleep 2

# Step 2: Nginx setup (if requested)
if [ "$INSTALL_NGINX" = true ]; then
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Step 2/3: Setting Up Nginx Reverse Proxy${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
    
    if [ ! -f "setup_nginx.sh" ]; then
        echo -e "${RED}[ERROR] setup_nginx.sh not found${NC}"
        echo -e "${YELLOW}Skipping nginx installation${NC}\n"
    else
        chmod +x setup_nginx.sh
        
        # Run nginx setup with domain name pre-configured
        if echo "$DOMAIN_NAME" | $SUDO_CMD ./setup_nginx.sh; then
            echo -e "\n${GREEN}✅ Nginx setup completed successfully!${NC}\n"
        else
            echo -e "\n${YELLOW}⚠️  Nginx setup encountered issues${NC}"
            echo -e "${YELLOW}You can run './setup_nginx.sh' manually later${NC}\n"
        fi
    fi
else
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Step 2/3: Nginx Setup - Skipped${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
    echo -e "${BLUE}ℹ️  You can add nginx later by running: sudo ./setup_nginx.sh${NC}\n"
fi

sleep 2

# Step 3: Systemd service (if requested)
if [ "$INSTALL_SERVICE" = true ]; then
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Step 3/3: Setting Up Systemd Service${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
    
    if [ ! -f "create_service.sh" ]; then
        echo -e "${RED}[ERROR] create_service.sh not found${NC}"
        echo -e "${YELLOW}Skipping service installation${NC}\n"
    else
        chmod +x create_service.sh
        
        echo -e "${YELLOW}Creating systemd service...${NC}\n"
        if $SUDO_CMD ./create_service.sh < /dev/null; then
            echo -e "\n${GREEN}✅ Systemd service setup completed!${NC}"
            
            # Verify service was created
            sleep 2
            if $SUDO_CMD systemctl list-unit-files | grep -q "selene.service"; then
                echo -e "${GREEN}✅ Service file verified${NC}\n"
                
                # Try to start the service
                echo -e "${YELLOW}Starting Selene service...${NC}"
                if $SUDO_CMD systemctl start selene 2>&1; then
                    sleep 3
                    if $SUDO_CMD systemctl is-active --quiet selene; then
                        echo -e "${GREEN}✅ Selene service is running!${NC}\n"
                    else
                        echo -e "${YELLOW}⚠️  Service created but not running${NC}"
                        echo -e "${YELLOW}Check logs: sudo journalctl -u selene -n 20${NC}\n"
                    fi
                else
                    echo -e "${YELLOW}⚠️  Could not start service automatically${NC}"
                    echo -e "${YELLOW}Start manually: sudo systemctl start selene${NC}\n"
                fi
            else
                echo -e "${RED}⚠️  Service file not found after creation${NC}"
                echo -e "${YELLOW}Try manually: sudo ./create_service.sh${NC}\n"
            fi
        else
            echo -e "\n${RED}⚠️  Service setup encountered errors${NC}"
            echo -e "${YELLOW}You can run 'sudo ./create_service.sh' manually later${NC}\n"
        fi
    fi
else
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Step 3/3: Systemd Service - Skipped${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"
    echo -e "${BLUE}ℹ️  You can add the service later by running: sudo ./create_service.sh${NC}\n"
fi

sleep 2

# Final summary
clear
echo -e "${GREEN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║              ✅  Installation Complete!  ✅                ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  🎉 Selene is Ready!${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}\n"

# Show access information
if [ "$INSTALL_NGINX" = true ]; then
    echo -e "${GREEN}📱 Access Selene at:${NC}"
    echo -e "${BLUE}   http://$DOMAIN_NAME${NC}"
    echo -e "${YELLOW}   (No port number needed!)${NC}\n"
else
    echo -e "${GREEN}📱 Access Selene at:${NC}"
    echo -e "${BLUE}   http://localhost:5000${NC}\n"
fi



# Show Ollama information
echo -e "${GREEN}🤖 AI Model:${NC}"
echo -e "${BLUE}   Make sure Ollama is running: ${NC}ollama serve"
echo -e "${BLUE}   Current model:               ${NC}$(grep OLLAMA_MODEL .env 2>/dev/null | cut -d= -f2 || echo "gemma3:4b")"
echo -e "${BLUE}   Change model:                ${NC}edit .env file\n"

# Network access information
if [ "$INSTALL_NGINX" = true ]; then
    echo -e "${GREEN}🌐 Network Access:${NC}"
    echo -e "${YELLOW}   To access from other devices on your network:${NC}"
    echo -e "${BLUE}   1. Find your IP:  ${NC}ip addr show | grep inet"
    echo -e "${BLUE}   2. On other devices, add to /etc/hosts:${NC}"
    echo -e "      ${CYAN}<your-ip>    $DOMAIN_NAME${NC}"
    echo -e "      ${CYAN}Example: 192.168.1.100    $DOMAIN_NAME${NC}\n"
fi

# Important notes
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  📋 Important Notes${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  • Place character images in the 'images/' directory${NC}"
echo -e "${YELLOW}  • Configuration file: .env${NC}"
echo -e "${YELLOW}  • Logs directory: logs/${NC}"
echo -e "${YELLOW}  • To change settings: edit .env and restart Selene${NC}\n"

# Troubleshooting
echo -e "${CYAN}🔍 Troubleshooting:${NC}"
echo -e "${BLUE}   View application logs: ${NC}tail -f logs/selene.log"
if [ "$INSTALL_NGINX" = true ]; then
    echo -e "${BLUE}   View nginx logs:       ${NC}sudo tail -f /var/log/nginx/selene_error.log"
fi
if [ "$INSTALL_SERVICE" = true ]; then
    echo -e "${BLUE}   View service logs:     ${NC}sudo journalctl -u selene -f"
fi
echo

# Final message
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Thank you for installing Selene! 🤖${NC}"
echo -e "${GREEN}  Enjoy chatting with your Fedora Linux AI assistant!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}\n"


exit 0
