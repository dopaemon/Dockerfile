#!/usr/bin/env bash

# Enable strict error handling and exit on failures
set -euo pipefail

# Logging function for container output
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling with cleanup
trap 'log "Error occurred. Exiting..."; exit 1' ERR

# Display startup configuration
log "Starting h5ai container with the following configuration:"
cat << EOF
    - TZ: ${TZ}
    - PUID: ${PUID}
    - PGID: ${PGID}
EOF

# Configure system timezone
log "Setting system timezone to: $TZ"
if [ -f "/usr/share/zoneinfo/$TZ" ]; then
    ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
    echo "$TZ" > /etc/timezone
else
    log "Warning: Timezone $TZ not found, using UTC as fallback"
    ln -sf "/usr/share/zoneinfo/UTC" /etc/localtime
    echo "UTC" > /etc/timezone
fi

# Configure PHP timezone
log "Configuring timezone for PHP: $TZ"
echo "[Date]" > /etc/php82/conf.d/00_timezone.ini
echo "date.timezone=\"$TZ\"" >> /etc/php82/conf.d/00_timezone.ini
sed -i "s|date.timezone=.*|date.timezone=\"$TZ\"|g" /etc/php82/conf.d/php_set_timezone.ini 2>/dev/null || true

# Setup user and permissions
log "Creating configuration directories..."
mkdir -p /config/{nginx,h5ai}
log "Setting up user permissions..."
if ! id abc >/dev/null 2>&1; then
    addgroup -g "$PGID" abc 2>/dev/null || true
    adduser -u "$PUID" -G abc -D -h /config -s /bin/false abc 2>/dev/null || true
else
    if [ "$(id -g abc)" != "$PGID" ]; then
        groupmod -o -g "$PGID" abc 2>/dev/null || log "Warning: Could not change group ID"
    fi
    if [ "$(id -u abc)" != "$PUID" ]; then
        usermod -o -u "$PUID" abc 2>/dev/null || log "Warning: Could not change user ID"
    fi
fi

# Define configuration paths
readonly ORIG_NGINX="/etc/nginx/conf.d/h5ai.conf"
readonly ORIG_H5AI="/usr/share/h5ai/_h5ai"
readonly CONF_NGINX="/config/nginx/h5ai.conf"
readonly CONF_H5AI="/config/h5ai/_h5ai"
readonly OPTIONS_FILE="/private/conf/options.json"

# Setup nginx configuration with persistence
setup_nginx_config() {
    log "Setting up Nginx configuration..."
    if [[ ! -f "$CONF_NGINX" ]]; then
        log "Copying default Nginx configuration..."
        cp "$ORIG_NGINX" "$CONF_NGINX"
    else
        log "Using existing Nginx configuration: $CONF_NGINX"
    fi
    rm -f "$ORIG_NGINX"
    ln -sf "$CONF_NGINX" "$ORIG_NGINX"
}

# Setup h5ai configuration with version management
setup_h5ai_config() {
    log "Setting up h5ai configuration..."
    if [[ ! -d "$CONF_H5AI" ]]; then
        log "Copying default h5ai configuration..."
        cp -a "$ORIG_H5AI" "$CONF_H5AI"
    else
        log "Using existing h5ai configuration: $CONF_H5AI"
        if [[ -f "$ORIG_H5AI$OPTIONS_FILE" && -f "$CONF_H5AI$OPTIONS_FILE" ]]; then
            local new_ver old_ver
            new_ver=$(awk 'NR==1 {gsub(/[^0-9]/, "", $3); print $3}' "$ORIG_H5AI$OPTIONS_FILE" 2>/dev/null || echo "0")
            old_ver=$(awk 'NR==1 {gsub(/[^0-9]/, "", $3); print $3}' "$CONF_H5AI$OPTIONS_FILE" 2>/dev/null || echo "0")
            if [[ $new_ver -gt $old_ver ]]; then
                log "New h5ai version detected. Backing up existing configuration..."
                cp "$CONF_H5AI$OPTIONS_FILE" "/config/$(date '+%Y%m%d_%H%M%S')_options.json.bak"
                rm -rf "$CONF_H5AI"
                cp -a "$ORIG_H5AI" "$CONF_H5AI"
            fi
        fi
    fi
    rm -rf "$ORIG_H5AI"
    ln -sf "$CONF_H5AI" "$ORIG_H5AI"
    log "Setting cache permissions..."
    chmod -R 755 "$CONF_H5AI/public/cache" "$CONF_H5AI/private/cache" 2>/dev/null || true
}

# Configure services with proper user assignment
configure_services() {
    log "Configuring PHP-FPM..."
    sed -i "s/user = nobody.*/user = abc/g" /etc/php82/php-fpm.d/www.conf
    sed -i "s/group = nobody.*/group = abc/g" /etc/php82/php-fpm.d/www.conf
    log "Setting file ownership..."
    chown -R abc:abc /config
}

# Execute main setup sequence
main() {
    setup_nginx_config
    setup_h5ai_config
    configure_services
    log "Starting supervisord..."
    exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
}

# Run main function
main "$@"
