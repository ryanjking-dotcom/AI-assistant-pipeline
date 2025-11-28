#!/bin/bash

# Selene Control Script - Manage Selene service with clear feedback
# Usage: ./selene-control.sh [start|stop|restart|status|logs|enable|disable]

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    SUDO_CMD="sudo"
else
    SUDO_CMD=""
fi

# Service name
SERVICE_NAME="selene"

# Function to check if service exists
check_service_exists() {
    if ! $SUDO_CMD systemctl list-unit-files | grep -q "^${SERVICE_NAME}.service"; then
        echo -e "${RED}❌ Error: ${SERVICE_NAME} service not found${NC}"
        echo -e "${YELLOW}💡 Install the service first: sudo ./create_service.sh${NC}"
        exit 1
    fi
}

# Function to show status
show_status() {
    if $SUDO_CMD systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${GREEN}✅ Selene is running${NC}"
        
        # Get PID if available
        PID=$($SUDO_CMD systemctl show -p MainPID --value $SERVICE_NAME)
        if [ "$PID" != "0" ] && [ -n "$PID" ]; then
            echo -e "${BLUE}   PID: ${NC}$PID"
        fi
        
        # Show uptime
        UPTIME=$($SUDO_CMD systemctl show -p ActiveEnterTimestamp --value $SERVICE_NAME)
        if [ -n "$UPTIME" ]; then
            echo -e "${BLUE}   Started: ${NC}$UPTIME"
        fi
        
        return 0
    else
        echo -e "${RED}❌ Selene is not running${NC}"
        return 1
    fi
}

# Function to start service
start_service() {
    echo -e "${CYAN}🚀 Starting Selene...${NC}"
    
    if $SUDO_CMD systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${YELLOW}⚠️  Selene is already running${NC}"
        show_status
        return 0
    fi
    
    if $SUDO_CMD systemctl start $SERVICE_NAME; then
        sleep 2
        if $SUDO_CMD systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}✅ Selene started successfully!${NC}"
            show_status
            return 0
        else
            echo -e "${RED}❌ Selene failed to start${NC}"
            echo -e "${YELLOW}💡 Check logs: sudo journalctl -u $SERVICE_NAME -n 20${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Failed to execute start command${NC}"
        return 1
    fi
}

# Function to stop service
stop_service() {
    echo -e "${CYAN}🛑 Stopping Selene...${NC}"
    
    if ! $SUDO_CMD systemctl is-active --quiet $SERVICE_NAME; then
        echo -e "${YELLOW}⚠️  Selene is not running${NC}"
        return 0
    fi
    
    if $SUDO_CMD systemctl stop $SERVICE_NAME; then
        sleep 2
        if ! $SUDO_CMD systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}✅ Selene stopped successfully${NC}"
            return 0
        else
            echo -e "${RED}❌ Selene is still running${NC}"
            echo -e "${YELLOW}💡 Try: sudo systemctl kill $SERVICE_NAME${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Failed to execute stop command${NC}"
        return 1
    fi
}

# Function to restart service
restart_service() {
    echo -e "${CYAN}🔄 Restarting Selene...${NC}"
    
    if $SUDO_CMD systemctl restart $SERVICE_NAME; then
        sleep 2
        if $SUDO_CMD systemctl is-active --quiet $SERVICE_NAME; then
            echo -e "${GREEN}✅ Selene restarted successfully!${NC}"
            show_status
            return 0
        else
            echo -e "${RED}❌ Selene failed to restart${NC}"
            echo -e "${YELLOW}💡 Check logs: sudo journalctl -u $SERVICE_NAME -n 20${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Failed to execute restart command${NC}"
        return 1
    fi
}

# Function to show detailed status
status_service() {
    echo -e "${CYAN}📊 Selene Service Status${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    
    show_status
    echo
    
    # Show if enabled
    if $SUDO_CMD systemctl is-enabled --quiet $SERVICE_NAME 2>/dev/null; then
        echo -e "${GREEN}🔧 Auto-start on boot: Enabled${NC}"
    else
        echo -e "${YELLOW}🔧 Auto-start on boot: Disabled${NC}"
    fi
    
    echo
    echo -e "${BLUE}📋 Detailed Status:${NC}"
    $SUDO_CMD systemctl status $SERVICE_NAME --no-pager -l
}

# Function to enable service
enable_service() {
    echo -e "${CYAN}⚙️  Enabling Selene auto-start...${NC}"
    
    if $SUDO_CMD systemctl is-enabled --quiet $SERVICE_NAME 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Selene auto-start is already enabled${NC}"
        return 0
    fi
    
    if $SUDO_CMD systemctl enable $SERVICE_NAME; then
        echo -e "${GREEN}✅ Selene will now start automatically on boot${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to enable auto-start${NC}"
        return 1
    fi
}

# Function to disable service
disable_service() {
    echo -e "${CYAN}⚙️  Disabling Selene auto-start...${NC}"
    
    if ! $SUDO_CMD systemctl is-enabled --quiet $SERVICE_NAME 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Selene auto-start is already disabled${NC}"
        return 0
    fi
    
    if $SUDO_CMD systemctl disable $SERVICE_NAME; then
        echo -e "${GREEN}✅ Selene will no longer start automatically on boot${NC}"
        echo -e "${BLUE}💡 The service is still running. Use 'stop' to stop it now.${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to disable auto-start${NC}"
        return 1
    fi
}

# Function to show logs
show_logs() {
    echo -e "${CYAN}📜 Selene Logs (Ctrl+C to exit)${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}\n"
    $SUDO_CMD journalctl -u $SERVICE_NAME -f
}

# Function to show recent logs
show_recent_logs() {
    echo -e "${CYAN}📜 Recent Selene Logs (last 50 lines)${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}\n"
    $SUDO_CMD journalctl -u $SERVICE_NAME -n 50 --no-pager
}

# Main script logic
check_service_exists

case "${1:-}" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    status)
        status_service
        ;;
    logs)
        show_logs
        ;;
    recent-logs)
        show_recent_logs
        ;;
    enable)
        enable_service
        ;;
    disable)
        disable_service
        ;;
    ""|--help|-h)
        echo -e "${CYAN}Selene Control Script${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}\n"
        echo -e "${GREEN}Usage:${NC} ./selene-control.sh [command]\n"
        echo -e "${BLUE}Commands:${NC}"
        echo -e "  ${GREEN}start${NC}         Start Selene service"
        echo -e "  ${GREEN}stop${NC}          Stop Selene service"
        echo -e "  ${GREEN}restart${NC}       Restart Selene service"
        echo -e "  ${GREEN}status${NC}        Show detailed service status"
        echo -e "  ${GREEN}logs${NC}          Show live logs (follow mode)"
        echo -e "  ${GREEN}recent-logs${NC}   Show last 50 log entries"
        echo -e "  ${GREEN}enable${NC}        Enable auto-start on boot"
        echo -e "  ${GREEN}disable${NC}       Disable auto-start on boot"
        echo -e "  ${GREEN}--help${NC}        Show this help message\n"
        echo -e "${YELLOW}Examples:${NC}"
        echo -e "  ./selene-control.sh start"
        echo -e "  ./selene-control.sh status"
        echo -e "  sudo ./selene-control.sh restart\n"
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo -e "${YELLOW}💡 Use './selene-control.sh --help' for usage information${NC}"
        exit 1
        ;;
esac

exit $?
