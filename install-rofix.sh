#!/bin/bash

# btrfs-rofix installer - Single script setup (Multi-location support)
# Save as install-rofix.sh, then: chmod +x install-rofix.sh && sudo ./install-rofix.sh

HOOK_NAME="btrfs-rofix"
INSTALL_DIRS=("/usr/lib/initcpio/install" "/etc/initcpio/install")
HOOK_DIRS=("/usr/lib/initcpio/hooks" "/etc/initcpio/hooks")
CONFIG_FILE="/etc/mkinitcpio.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Check root
[ "$EUID" -ne 0 ] && error_exit "Run as root: sudo $0"

# Install script to all install locations
for INSTALL_DIR in "${INSTALL_DIRS[@]}"; do
    mkdir -p "$INSTALL_DIR" || error_exit "Failed to create $INSTALL_DIR"
    cat > "$INSTALL_DIR/$HOOK_NAME" << 'EOF'
#!/bin/bash

build() {
    add_module "btrfs"
    add_binary "btrfs"
    add_binary "btrfsck"
    add_runscript
}

help() {
    cat <<'HELP_EOF'
This hook sets property ro=false in snapshot via "btrfs property set /new_root ro false"
command for boot into read-only snapshot without errors.
HELP_EOF
}
EOF
    chmod +x "$INSTALL_DIR/$HOOK_NAME"
    echo -e "${GREEN}✓ Created $INSTALL_DIR/$HOOK_NAME${NC}"
done

# Hook script to all hooks locations
for HOOK_DIR in "${HOOK_DIRS[@]}"; do
    mkdir -p "$HOOK_DIR" || error_exit "Failed to create $HOOK_DIR"
    cat > "$HOOK_DIR/$HOOK_NAME" << 'EOF'
#!/bin/bash

run_hook() {
    if [ -e "/new_root" ]; then
        btrfs property set /new_root ro false
        echo "Set /new_root to read-write"
    fi
}
EOF
    chmod +x "$HOOK_DIR/$HOOK_NAME"
    echo -e "${GREEN}✓ Created $HOOK_DIR/$HOOK_NAME${NC}"
done

# Backup mkinitcpio.conf
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak-rofix" || error_exit "Failed to backup config"

# Add hook to HOOKS (insert before filesystems if not already present)
if ! grep -q "$HOOK_NAME" "$CONFIG_FILE"; then
    sed -i "/HOOKS=(/ {
        /filesystems/!b
        s/\(filesystems\)/\1 $HOOK_NAME/
    }" "$CONFIG_FILE" || {
        # Fallback: append before closing parenthesis
        sed -i "/HOOKS=/,/)/s/)$/ $HOOK_NAME)/" "$CONFIG_FILE"
    }
    echo -e "${GREEN}✓ Hook '$HOOK_NAME' added to $CONFIG_FILE${NC}"
else
    echo -e "${YELLOW}✓ Hook '$HOOK_NAME' already in config${NC}"
fi

echo -e "\n${GREEN}✓ Installation complete! All locations supported:${NC}"
echo "  Install: ${INSTALL_DIRS[*]}"
echo "  Hooks:   ${HOOK_DIRS[*]}"
echo -e "${YELLOW}✓ Backup: ${CONFIG_FILE}.bak-rofix${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. mkinitcpio -P"
echo "2. grub-mkconfig -o /boot/grub/grub.cfg  (if using GRUB)"
echo "3. Reboot to test"
echo ""
echo -e "${YELLOW}Uninstall:${NC}"
echo "sudo ./uninstall-rofix.sh  (create this if needed) or manually remove files"
