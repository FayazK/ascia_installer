#!/bin/bash
#
# Ascia UI Direct Installer for Home Assistant
# This script installs Ascia UI directly without using the add-on system
# Version: 1.0.0
#

# Print banner
echo "=================================================="
echo "Ascia UI Direct Installer for Home Assistant"
echo "Version: 1.0.0"
echo "=================================================="

# Set default variables
REPO="https://github.com/FayazK/ascia_ui.git"
BRANCH="main"
MAKE_BACKUP="true"
RESTART_HA="true"
HA_CONFIG_DIR="/config"  # Default Home Assistant config directory

# Process command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --repo=*)
      REPO="${1#*=}"
      shift
      ;;
    --branch=*)
      BRANCH="${1#*=}"
      shift
      ;;
    --no-backup)
      MAKE_BACKUP="false"
      shift
      ;;
    --no-restart)
      RESTART_HA="false"
      shift
      ;;
    --config-dir=*)
      HA_CONFIG_DIR="${1#*=}"
      shift
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --repo=URL          Repository URL (default: $REPO)"
      echo "  --branch=BRANCH     Repository branch (default: $BRANCH)"
      echo "  --no-backup         Skip making backups"
      echo "  --no-restart        Skip restarting Home Assistant"
      echo "  --config-dir=PATH   Home Assistant config directory (default: $HA_CONFIG_DIR)"
      echo "  --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Print configuration
echo "Repository: $REPO"
echo "Branch: $BRANCH"
echo "Make backup: $MAKE_BACKUP"
echo "Restart HA after install: $RESTART_HA"
echo "Home Assistant config directory: $HA_CONFIG_DIR"
echo "=================================================="

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "[!] ERROR: git is not installed."
    echo "Please install git first using: apt-get update && apt-get install -y git"
    exit 1
fi

# Define target directories
TARGET="$HA_CONFIG_DIR/custom_frontend"
CONFIG="$HA_CONFIG_DIR/configuration.yaml"
BACKUP_DIR="$HA_CONFIG_DIR/backups/ascia"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Check for configuration.yaml
if [ ! -f "$CONFIG" ]; then
    echo "[!] ERROR: configuration.yaml not found at $CONFIG"
    echo "Please specify the correct Home Assistant config directory with --config-dir="
    exit 1
fi

# Create backup if requested
if [ "$MAKE_BACKUP" = "true" ]; then
    echo "[*] Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
    
    echo "[*] Creating configuration backup..."
    cp "$CONFIG" "$BACKUP_DIR/configuration.yaml.$TIMESTAMP"
    echo "[+] Backup saved to $BACKUP_DIR/configuration.yaml.$TIMESTAMP"
    
    if [ -d "$TARGET" ]; then
        echo "[*] Backing up existing custom UI..."
        tar -czf "$BACKUP_DIR/custom_frontend.$TIMESTAMP.tar.gz" -C "$(dirname "$TARGET")" "$(basename "$TARGET")"
        echo "[+] Custom UI backup saved to $BACKUP_DIR/custom_frontend.$TIMESTAMP.tar.gz"
    fi
fi

# Verify repository
echo "[*] Verifying repository..."
if ! git ls-remote --exit-code "$REPO" &>/dev/null; then
    echo "[!] ERROR: Repository $REPO is not accessible"
    exit 1
fi

# Download repository
echo "[*] Downloading Ascia UI from $REPO ($BRANCH branch)..."
if [ -d "$TARGET" ]; then
    echo "[*] Removing old installation..."
    rm -rf "$TARGET"
fi

echo "[*] Cloning repository..."
if ! git clone --depth=1 --branch "$BRANCH" "$REPO" "$TARGET"; then
    echo "[!] ERROR: Failed to clone repository"
    echo "[*] Restoring from backup if available..."
    if [ "$MAKE_BACKUP" = "true" ] && [ -f "$BACKUP_DIR/configuration.yaml.$TIMESTAMP" ]; then
        cp "$BACKUP_DIR/configuration.yaml.$TIMESTAMP" "$CONFIG"
    fi
    exit 1
fi

# Validate downloaded content
echo "[*] Validating downloaded content..."
if [ ! -d "$TARGET" ]; then
    echo "[!] ERROR: Download failed or target directory not created"
    exit 1
fi

# Check for suspicious content
echo "[*] Running security checks on downloaded content..."
SUSPICIOUS=$(find "$TARGET" -name "*.sh" -o -name "*.py" | wc -l)
if [ "$SUSPICIOUS" -gt 10 ]; then
    echo "[!] WARNING: Found a high number of scripts in the downloaded content"
    echo "    This might indicate malicious content. Review the content before continuing."
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "[*] Installation aborted by user"
        exit 1
    fi
fi

# Update Home Assistant configuration
echo "[*] Updating Home Assistant configuration..."

# More robust configuration update
if grep -q "frontend:" "$CONFIG"; then
    echo "[*] Frontend configuration found, updating..."
    if grep -q "development_repo:" "$CONFIG"; then
        echo "[*] Updating existing development_repo setting..."
        # Use more specific pattern to avoid accidental replacements
        sed -i "/frontend:/{n; s|.*development_repo:.*|  development_repo: $TARGET|}" "$CONFIG"
    else
        echo "[*] Adding development_repo setting..."
        sed -i "/frontend:/a\\  development_repo: $TARGET" "$CONFIG"
    fi
else
    echo "[*] Adding frontend configuration..."
    echo -e "\nfrontend:\n  development_repo: $TARGET" >> "$CONFIG"
fi

# Verify configuration changes
if ! grep -q "development_repo: $TARGET" "$CONFIG"; then
    echo "[!] ERROR: Failed to update configuration.yaml"
    echo "[*] Restoring from backup if available..."
    if [ "$MAKE_BACKUP" = "true" ] && [ -f "$BACKUP_DIR/configuration.yaml.$TIMESTAMP" ]; then
        cp "$BACKUP_DIR/configuration.yaml.$TIMESTAMP" "$CONFIG"
    fi
    exit 1
fi

# Create documentation for the user
echo "[*] Creating documentation for the user..."
mkdir -p "$TARGET/docs"
cat > "$TARGET/docs/README.md" << EOF
# Ascia UI for Home Assistant

Installation Date: $(date)
Repository: $REPO
Branch: $BRANCH

## Usage
The custom UI should be automatically loaded when you access your Home Assistant interface.
If you encounter any issues, you can:

1. Clear your browser cache
2. Restart Home Assistant
3. Check the logs for any errors

## Uninstallation
To uninstall, remove the 'frontend:' and 'development_repo:' lines from your configuration.yaml file,
then restart Home Assistant.

## Backup
Your original configuration has been backed up to: $BACKUP_DIR
EOF

# Restart Home Assistant if requested
if [ "$RESTART_HA" = "true" ]; then
    echo "[*] Restarting Home Assistant..."
    
    # Try different methods to restart Home Assistant
    # Method 1: Using HA CLI
    if command -v ha &> /dev/null; then
        echo "[*] Using HA CLI to restart..."
        ha core restart
    # Method 2: Using Home Assistant API
    elif [ -n "$HASS_API_TOKEN" ] && command -v curl &> /dev/null; then
        echo "[*] Using Home Assistant API to restart..."
        curl -X POST -H "Authorization: Bearer $HASS_API_TOKEN" \
             -H "Content-Type: application/json" \
             http://localhost:8123/api/services/homeassistant/restart
    # Method 3: Using systemctl
    elif command -v systemctl &> /dev/null && systemctl is-active --quiet home-assistant@homeassistant.service; then
        echo "[*] Using systemctl to restart..."
        systemctl restart home-assistant@homeassistant.service
    else
        echo "[!] WARNING: Could not automatically restart Home Assistant"
        echo "[!] IMPORTANT: You need to restart Home Assistant manually for changes to take effect"
    fi
    
    echo "[*] Waiting for Home Assistant to come back online..."
    sleep 10
    echo "[*] Home Assistant should be restarting now."
    echo "[*] Please wait a few minutes for it to become fully operational."
else
    echo "[*] Skipping Home Assistant restart as per configuration"
    echo "[!] IMPORTANT: You need to restart Home Assistant manually for changes to take effect"
fi

echo "[+] Installation completed successfully!"
echo "    Ascia UI has been installed to: $TARGET"
echo "    Configuration updated: $CONFIG"

if [ "$MAKE_BACKUP" = "true" ]; then
    echo "    Backup saved to: $BACKUP_DIR"
fi

echo "    Enjoy your new Home Assistant UI!"
exit 0