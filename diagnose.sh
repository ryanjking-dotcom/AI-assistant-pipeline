#!/bin/bash

# Selene Diagnostic Script
# Checks all components and identifies issues

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Selene Diagnostic Tool                    ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}\n"

# Test 1: Check if Selene (Flask) is running
echo -e "${YELLOW}[1/7] Checking if Selene is running...${NC}"
if curl -s http://localhost:5000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Selene is running on port 5000${NC}\n"
    SELENE_RUNNING=true
else
    echo -e "${RED}❌ Selene is NOT running on port 5000${NC}"
    echo -e "${YELLOW}   This is likely why you're getting nginx errors!${NC}\n"
    SELENE_RUNNING=false
fi

# Test 2: Check if nginx is running
echo -e "${YELLOW}[2/7] Checking if nginx is running...${NC}"
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo -e "${GREEN}✅ Nginx is running${NC}\n"
    NGINX_RUNNING=true
elif pgrep nginx > /dev/null; then
    echo -e "${GREEN}✅ Nginx is running${NC}\n"
    NGINX_RUNNING=true
else
    echo -e "${RED}❌ Nginx is NOT running${NC}\n"
    NGINX_RUNNING=false
fi

# Test 3: Check nginx configuration
echo -e "${YELLOW}[3/7] Testing nginx configuration...${NC}"
if command -v nginx &> /dev/null; then
    if sudo nginx -t 2>&1 | grep -q "successful"; then
        echo -e "${GREEN}✅ Nginx configuration is valid${NC}\n"
    else
        echo -e "${RED}❌ Nginx configuration has errors:${NC}"
        sudo nginx -t
        echo
    fi
else
    echo -e "${YELLOW}⚠️  Nginx not installed${NC}\n"
fi

# Test 4: Check if Selene service exists
echo -e "${YELLOW}[4/7] Checking Selene systemd service...${NC}"
if systemctl list-unit-files | grep -q selene.service; then
    if systemctl is-active --quiet selene; then
        echo -e "${GREEN}✅ Selene service is running${NC}\n"
    else
        echo -e "${RED}❌ Selene service exists but is NOT running${NC}"
        echo -e "${BLUE}   Status:${NC}"
        systemctl status selene --no-pager -l
        echo
    fi
else
    echo -e "${YELLOW}⚠️  Selene service not installed${NC}"
    echo -e "${BLUE}   Checking for manual process...${NC}"
    if pgrep -f "python.*assistant.py" > /dev/null; then
        echo -e "${GREEN}   ✅ Selene is running manually${NC}\n"
    else
        echo -e "${RED}   ❌ Selene is not running at all${NC}\n"
    fi
fi

# Test 5: Check Ollama
echo -e "${YELLOW}[5/7] Checking Ollama...${NC}"
if curl -s http://localhost:11434/api/version > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Ollama is running${NC}"
    OLLAMA_VERSION=$(curl -s http://localhost:11434/api/version | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    echo -e "${BLUE}   Version: $OLLAMA_VERSION${NC}\n"
else
    echo -e "${RED}❌ Ollama is NOT running${NC}"
    echo -e "${YELLOW}   Selene needs Ollama to function!${NC}\n"
fi

# Test 6: Check ports
echo -e "${YELLOW}[6/7] Checking ports...${NC}"
if command -v ss &> /dev/null; then
    echo -e "${BLUE}Port 5000 (Selene):${NC}"
    if ss -tlnp 2>/dev/null | grep -q ":5000"; then
        echo -e "${GREEN}✅ Something is listening on port 5000${NC}"
        ss -tlnp 2>/dev/null | grep ":5000"
    else
        echo -e "${RED}❌ Nothing listening on port 5000${NC}"
    fi
    
    echo -e "\n${BLUE}Port 80 (nginx):${NC}"
    if ss -tlnp 2>/dev/null | grep -q ":80"; then
        echo -e "${GREEN}✅ Something is listening on port 80${NC}"
        ss -tlnp 2>/dev/null | grep ":80"
    else
        echo -e "${RED}❌ Nothing listening on port 80${NC}"
    fi
    echo
else
    echo -e "${YELLOW}⚠️  'ss' command not available, skipping port check${NC}\n"
fi

# Test 7: Check logs
echo -e "${YELLOW}[7/7] Recent logs...${NC}"
echo -e "${BLUE}Application logs:${NC}"
if [ -f "logs/selene.log" ]; then
    tail -n 5 logs/selene.log
else
    echo -e "${YELLOW}   No application logs found${NC}"
fi

echo -e "\n${BLUE}Nginx error logs:${NC}"
if [ -f "/var/log/nginx/selene_error.log" ]; then
    sudo tail -n 5 /var/log/nginx/selene_error.log 2>/dev/null || echo -e "${YELLOW}   Cannot read nginx logs (need sudo)${NC}"
else
    echo -e "${YELLOW}   No nginx logs found${NC}"
fi

# Summary and recommendations
echo -e "\n${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Diagnostic Summary                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"

if [ "$SELENE_RUNNING" = false ]; then
    echo -e "${RED}🔴 MAIN ISSUE: Selene is not running!${NC}\n"
    echo -e "${YELLOW}Quick fixes to try:${NC}"
    echo -e "${BLUE}1. Start manually:${NC}"
    echo -e "   ./run.sh"
    echo -e "${BLUE}2. Or start as service:${NC}"
    echo -e "   sudo systemctl start selene"
    echo -e "${BLUE}3. Check for errors:${NC}"
    echo -e "   python3 assistant.py"
    echo
elif [ "$NGINX_RUNNING" = false ]; then
    echo -e "${RED}🔴 ISSUE: Nginx is not running!${NC}\n"
    echo -e "${YELLOW}Quick fix:${NC}"
    echo -e "   sudo systemctl start nginx"
    echo
else
    echo -e "${GREEN}✅ All main components appear to be running${NC}\n"
    echo -e "${YELLOW}If you're still seeing errors, check:${NC}"
    echo -e "${BLUE}1. Firewall:${NC} sudo ufw status"
    echo -e "${BLUE}2. SELinux:${NC} sudo getenforce"
    echo -e "${BLUE}3. Full logs:${NC} sudo journalctl -u selene -n 50"
    echo
fi

# Additional helpful commands
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Useful Commands                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}\n"
echo -e "${YELLOW}View real-time logs:${NC}"
echo -e "  tail -f logs/selene.log"
echo -e "  sudo tail -f /var/log/nginx/selene_error.log"
echo -e "  sudo journalctl -u selene -f"
echo
echo -e "${YELLOW}Restart services:${NC}"
echo -e "  sudo systemctl restart nginx"
echo -e "  sudo systemctl restart selene"
echo
echo -e "${YELLOW}Test direct access (bypass nginx):${NC}"
echo -e "  curl http://localhost:5000"
echo -e "  Or open in browser: http://localhost:5000"
echo
