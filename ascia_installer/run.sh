#!/usr/bin/env bash

# Improved Ascia UI Installer Script
# Enhanced with better error handling, backup features, and security

# Exit on error, but with proper cleanup
set -e

# Access the configuration options
CONFIG_PATH=/data/options.json

# Parse config
REPO=$(jq --raw-output '.repo // "https://github.com/FayazK/ascia_ui.git"' $CONFIG_PATH)
BRANCH=$(jq --raw-output '.branch // "main"' $CONFIG_PATH)
MAKE_BACKUP=$(jq --raw-output '.make_backup // true' $CONFIG_PATH)
RESTART_HA=$(jq --raw-output '.restart_ha // true' $CONFIG_PATH)

# Target directories
TARGET=/config/custom_frontend
CONFIG=/config/configuration.yaml
BACKUP_DIR=/config/backups/ascia
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Print banner
echo "=================================================="
echo "Ascia UI Installer for Home Assistant"
echo "Version: 0.1.0"
echo "=================================================="
echo "Repository: $REPO"
echo "Branch: $BRANCH"
echo "Make backup: $MAKE_BACKUP"
echo "Restart HA after install: $RESTART_HA"
echo "=================================================="

# Create backup directory if needed
if [ "$MAKE_BACKUP" = "true" ]; then
    echo "[*] Creating backup directory..."
    mkdir -p $BACKUP_DIR
    
    echo "[*] Creating configuration backup..."
    if [ -f "$CONFIG" ]; then
        cp "$CONFIG" "$BACKUP_DIR/configuration.yaml.$TIMESTAMP"
        echo "[+] Backup saved to $BACKUP_DIR/configuration.yaml.$TIMESTAMP"
    else
        echo "[!] Warning: configuration.yaml not found, skipping backup"
    fi
    
    if [ -d "$TARGET" ]; then
        echo "[*] Backing up existing custom UI..."
        tar -czf "$BACKUP_DIR/custom_frontend.$TIMESTAMP.tar.gz" -C "$(dirname "$TARGET")" "$(basename "$TARGET")"
        echo "[+] Custom UI backup saved to $BACKUP_DIR/custom_frontend.$TIMESTAMP.tar.gz"
    fi
fi

# Verify repository before downloading
echo "[*] Verifying repository..."
if ! git ls-remote --exit-code "$REPO" &>/dev/null; then
    echo "[!] ERROR: Repository $REPO is not accessible"
    exit 1
fi

# Download repository with specific branch
echo "[*] Downloading Ascia UI from $REPO ($BRANCH branch)..."
if [ -d "$TARGET" ]; then
    echo "[*] Removing old installation..."
    rm -rf "$TARGET"
fi

echo "[*] Cloning repository..."
# Clone with proper error handling
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
    echo "    To proceed anyway, reinstall with custom options."
    exit 1
fi

# Update Home Assistant configuration
echo "[*] Updating Home Assistant configuration..."
if [ ! -f "$CONFIG" ]; then
    echo "[!] ERROR: configuration.yaml not found"
    exit 1
fi

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
    echo "[*] Restarting Home Assistant Core..."
    ha core restart
    echo "[*] Waiting for Home Assistant to come back online..."
    sleep 5
    # Check if Home Assistant is back online
    MAX_ATTEMPTS=12
    ATTEMPTS=0
    while [ $ATTEMPTS -lt $MAX_ATTEMPTS ]; do
        if curl -s "http://supervisor/core/api/config" -H "Authorization: Bearer $SUPERVISOR_TOKEN" | grep -q "version"; then
            echo "[+] Home Assistant is back online"
            break
        fi
        echo "[*] Still waiting for Home Assistant..."
        sleep 10
        ATTEMPTS=$((ATTEMPTS + 1))
    done
    
    if [ $ATTEMPTS -eq $MAX_ATTEMPTS ]; then
        echo "[!] WARNING: Home Assistant restart is taking longer than expected"
        echo "    Installation completed but Home Assistant might still be restarting"
    fi
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
