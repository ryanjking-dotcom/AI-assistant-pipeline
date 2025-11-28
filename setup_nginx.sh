#!/bin/bash

# Selene AI Assistant - Nginx Reverse Proxy Setup
# This script configures nginx to serve Selene with a custom domain

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run with sudo${NC}"
    echo "Usage: sudo ./setup_nginx.sh"
    exit 1
fi

echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}🌐 Selene - Nginx Reverse Proxy Setup${NC}"
echo -e "${BLUE}============================================================${NC}\n"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    echo -e "${BLUE}Detected OS: $NAME${NC}\n"
fi

# Ask for domain name
echo -e "${YELLOW}What domain name would you like to use?${NC}"
echo -e "${BLUE}Examples:${NC}"
echo -e "  - selene.local"
echo -e "  - chat.selene"
echo -e "  - selene.ai"
echo -e "  - myassistant.local"
echo ""

# Check if domain was provided via stdin (for automation)
if [ -t 0 ]; then
    # Interactive mode
    read -p "Enter domain name [selene.local]: " DOMAIN_NAME
    DOMAIN_NAME=${DOMAIN_NAME:-selene.local}
else
    # Non-interactive mode (piped input)
    read DOMAIN_NAME
    DOMAIN_NAME=${DOMAIN_NAME:-selene.local}
fi

echo -e "\n${GREEN}Using domain: $DOMAIN_NAME${NC}\n"

# Install nginx if not already installed
echo -e "${YELLOW}Checking nginx installation...${NC}"
if ! command -v nginx &> /dev/null; then
    echo -e "${YELLOW}Installing nginx...${NC}"
    
    if [[ "$OS_ID" == "ubuntu" ]] || [[ "$OS_ID" == "debian" ]]; then
        apt update
        apt install -y nginx
    elif [[ "$OS_ID" == "fedora" ]] || [[ "$OS_ID" == "nobara" ]] || [[ "$OS_ID" == "rhel" ]]; then
        dnf install -y nginx
    else
        echo -e "${RED}[ERROR] Unsupported OS. Please install nginx manually.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}[OK] Nginx installed${NC}\n"
else
    echo -e "${GREEN}[OK] Nginx already installed${NC}\n"
fi

# Create nginx configuration
echo -e "${YELLOW}Creating nginx configuration...${NC}"

NGINX_CONF="/etc/nginx/sites-available/selene"
NGINX_ENABLED="/etc/nginx/sites-enabled/selene"

# For Fedora/RHEL, use different path
if [[ "$OS_ID" == "fedora" ]] || [[ "$OS_ID" == "nobara" ]] || [[ "$OS_ID" == "rhel" ]]; then
    NGINX_CONF="/etc/nginx/conf.d/selene.conf"
fi

cat > "$NGINX_CONF" << EOF
# Selene AI Assistant - Nginx Configuration
# Domain: $DOMAIN_NAME

server {
    listen 80;
    server_name $DOMAIN_NAME;

    # Increase client body size for file uploads (if needed in future)
    client_max_body_size 16M;

    # Main application
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        
        # Headers
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket support (for future use)
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts (important for long AI responses)
        proxy_connect_timeout 600s;
        proxy_send_timeout 600s;
        proxy_read_timeout 600s;
    }

    # Access and error logs
    access_log /var/log/nginx/selene_access.log;
    error_log /var/log/nginx/selene_error.log;
}
EOF

echo -e "${GREEN}[OK] Nginx configuration created${NC}\n"

# Enable site (Ubuntu/Debian only)
if [[ "$OS_ID" == "ubuntu" ]] || [[ "$OS_ID" == "debian" ]]; then
    echo -e "${YELLOW}Enabling site...${NC}"
    
    # Create sites-enabled directory if it doesn't exist
    mkdir -p /etc/nginx/sites-enabled
    
    # Remove existing symlink if it exists
    if [ -L "$NGINX_ENABLED" ]; then
        rm "$NGINX_ENABLED"
    fi
    
    # Create symlink
    ln -s "$NGINX_CONF" "$NGINX_ENABLED"
    
    echo -e "${GREEN}[OK] Site enabled${NC}\n"
fi

# Test nginx configuration
echo -e "${YELLOW}Testing nginx configuration...${NC}"
if nginx -t 2>&1 | grep -q "successful"; then
    echo -e "${GREEN}[OK] Nginx configuration valid${NC}\n"
else
    echo -e "${RED}[ERROR] Nginx configuration has errors${NC}"
    nginx -t
    exit 1
fi

# Configure SELinux (Fedora/RHEL only)
if [[ "$OS_ID" == "fedora" ]] || [[ "$OS_ID" == "nobara" ]] || [[ "$OS_ID" == "rhel" ]]; then
    echo -e "${YELLOW}Configuring SELinux for nginx...${NC}"
    if command -v semanage &> /dev/null; then
        # Allow nginx to connect to port 5000
        semanage port -a -t http_port_t -p tcp 5000 2>/dev/null || semanage port -m -t http_port_t -p tcp 5000
        setsebool -P httpd_can_network_connect 1
        echo -e "${GREEN}[OK] SELinux configured${NC}\n"
    else
        echo -e "${YELLOW}[WARNING] semanage not found, you may need to configure SELinux manually${NC}\n"
    fi
fi

# Start and enable nginx
echo -e "${YELLOW}Starting nginx...${NC}"
systemctl enable nginx
systemctl restart nginx
echo -e "${GREEN}[OK] Nginx started and enabled${NC}\n"

# Check if nginx is running
if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✅ Nginx is running successfully${NC}\n"
else
    echo -e "${RED}[ERROR] Nginx failed to start${NC}"
    systemctl status nginx
    exit 1
fi

# Add to /etc/hosts if not already there
echo -e "${YELLOW}Updating /etc/hosts file...${NC}"
if grep -q "$DOMAIN_NAME" /etc/hosts; then
    echo -e "${GREEN}[OK] $DOMAIN_NAME already in /etc/hosts${NC}\n"
else
    echo "127.0.0.1    $DOMAIN_NAME" >> /etc/hosts
    echo -e "${GREEN}[OK] Added $DOMAIN_NAME to /etc/hosts${NC}\n"
fi

# Configure firewall if available
echo -e "${YELLOW}Configuring firewall...${NC}"
if command -v ufw &> /dev/null; then
    # Ubuntu firewall
    ufw allow 'Nginx HTTP' 2>/dev/null || ufw allow 80/tcp
    echo -e "${GREEN}[OK] UFW configured for HTTP${NC}\n"
elif command -v firewall-cmd &> /dev/null; then
    # Fedora/RHEL firewall
    firewall-cmd --permanent --add-service=http
    firewall-cmd --reload
    echo -e "${GREEN}[OK] Firewalld configured for HTTP${NC}\n"
else
    echo -e "${YELLOW}[WARNING] No firewall detected, make sure port 80 is open${NC}\n"
fi

# Final instructions
echo -e "${BLUE}============================================================${NC}"
echo -e "${GREEN}✅ Nginx Setup Complete!${NC}"
echo -e "${BLUE}============================================================${NC}\n"

echo -e "${YELLOW}Access Selene at:${NC}"
echo -e "${GREEN}  http://$DOMAIN_NAME${NC}"
echo -e "${BLUE}  (No port number needed!)${NC}\n"

echo -e "${YELLOW}Important:${NC}"
echo -e "1. Make sure Selene is running: ${BLUE}./run.sh${NC}"
echo -e "2. Or start as service: ${BLUE}sudo systemctl start selene${NC}\n"

echo -e "${YELLOW}Access from other devices on your network:${NC}"
echo -e "1. Find your server's IP: ${BLUE}ip addr show${NC}"
echo -e "2. On other devices, add to their /etc/hosts:"
echo -e "   ${BLUE}<your-server-ip>    $DOMAIN_NAME${NC}"
echo -e "   Example: ${BLUE}192.168.1.100    $DOMAIN_NAME${NC}\n"

echo -e "${YELLOW}Useful nginx commands:${NC}"
echo -e "  Check status:  ${BLUE}sudo systemctl status nginx${NC}"
echo -e "  Restart:       ${BLUE}sudo systemctl restart nginx${NC}"
echo -e "  View logs:     ${BLUE}sudo tail -f /var/log/nginx/selene_access.log${NC}"
echo -e "  Test config:   ${BLUE}sudo nginx -t${NC}\n"

echo -e "${YELLOW}To add HTTPS (SSL) later:${NC}"
echo -e "  ${BLUE}sudo apt install certbot python3-certbot-nginx${NC}  (Ubuntu)"
echo -e "  ${BLUE}sudo dnf install certbot python3-certbot-nginx${NC}  (Fedora)"
echo -e "  ${BLUE}sudo certbot --nginx -d $DOMAIN_NAME${NC}\n"

echo -e "${GREEN}Enjoy your clean URL! 🎉${NC}\n"
