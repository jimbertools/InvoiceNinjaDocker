#!/bin/bash
set -e

# Set PDF generation browser path based on architecture
if [ "$(dpkg --print-architecture)" = "amd64" ]; then
    export SNAPPDF_CHROMIUM_PATH=/usr/bin/google-chrome-stable
elif [ "$(dpkg --print-architecture)" = "arm64" ]; then
    export SNAPPDF_CHROMIUM_PATH=/usr/bin/chromium
fi

# Ensure storage directories exist and have correct permissions
mkdir -p /var/www/html/storage/logs \
         /var/www/html/storage/framework/cache \
         /var/www/html/storage/framework/sessions \
         /var/www/html/storage/framework/views \
         /var/www/html/bootstrap/cache

# Fix permissions for writable directories
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

# Run Laravel optimizations and migrations if in production
if [ "${APP_ENV:-production}" = "production" ]; then
    echo "Running Laravel optimizations..."
    runuser -u www-data -- php /var/www/html/artisan optimize 2>/dev/null || true
    runuser -u www-data -- php /var/www/html/artisan package:discover 2>/dev/null || true
    
    # Wait for database to be ready (up to 60 seconds)
    echo "Waiting for database connection..."
    for i in $(seq 1 60); do
        if php /var/www/html/artisan tinker --execute='DB::connection()->getPdo();' 2>/dev/null; then
            echo "Database is ready!"
            break
        fi
        echo "Waiting for database... ($i/60)"
        sleep 1
    done
    
    # Run migrations
    runuser -u www-data -- php /var/www/html/artisan migrate --force 2>/dev/null || true

    # Initialize database if this is the first run
    NEEDS_INIT=$(php -d opcache.preload='' /var/www/html/artisan tinker --execute='echo Schema::hasTable("accounts") && !App\Models\Account::all()->first();' 2>/dev/null || echo "0")
    if [ "$NEEDS_INIT" = "1" ]; then
        echo "Running first-time initialization..."
        php /var/www/html/artisan db:seed --force 2>/dev/null || true
        if [ -n "${IN_USER_EMAIL:-}" ] && [ -n "${IN_PASSWORD:-}" ]; then
            php /var/www/html/artisan ninja:create-account --email "${IN_USER_EMAIL}" --password "${IN_PASSWORD}" 2>/dev/null || true
        fi
    fi
fi

echo "Starting services..."

# Execute the main command (supervisord)
exec "$@"
