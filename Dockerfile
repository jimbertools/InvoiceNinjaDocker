# Start from the Invoice Ninja Debian-based image
FROM invoiceninja/invoiceninja-debian:5.11

# Temporarily switch to root to install Nginx and Supervisor
USER root

# Install Nginx and Supervisor, set permissions
RUN apt-get update && \
    apt-get install -y nginx supervisor && \
    mkdir -p /run/nginx /var/log/nginx /var/run/supervisor /var/log/supervisord && \
    touch /var/log/queue-worker.log && touch /var/log/queue-worker-error.log && \
    chown -R www-data:www-data /run/nginx /var/log/nginx /var/lib/nginx /var/log/supervisord /var/run/supervisor \
    /var/log/queue-worker.log /var/log/queue-worker-error.log && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Disable opcache preload (causes issues) and configure PHP for production
RUN find /usr/local/etc -type f -name "*.ini" -exec sed -i 's|^opcache.preload=|;opcache.preload=|g' {} \; && \
    find /usr/local/etc -type f -name "*.ini" -exec sed -i 's|^opcache.preload_user=|;opcache.preload_user=|g' {} \; && \
    echo "display_errors = Off" >> /usr/local/etc/php/conf.d/invoice-ninja.ini && \
    echo "display_startup_errors = Off" >> /usr/local/etc/php/conf.d/invoice-ninja.ini && \
    echo "log_errors = On" >> /usr/local/etc/php/conf.d/invoice-ninja.ini && \
    echo "error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT" >> /usr/local/etc/php/conf.d/invoice-ninja.ini && \
    echo "output_buffering = 4096" >> /usr/local/etc/php/conf.d/invoice-ninja.ini

# Move public files from /tmp/public to /var/www/html/public at build time
# The base image places these in /tmp/public to allow volume mounts
RUN if [ -d /tmp/public ] && [ "$(ls -A /tmp/public 2>/dev/null)" ]; then \
        echo "Moving public folder at build time..." && \
        rm -rf /var/www/html/public 2>/dev/null || true && \
        mv /tmp/public /var/www/html/public && \
        echo "Public folder moved successfully"; \
    fi

# Fix permissions for Laravel storage and cache directories
RUN mkdir -p /var/www/html/storage/logs /var/www/html/storage/framework/cache /var/www/html/storage/framework/sessions /var/www/html/storage/framework/views /var/www/html/bootstrap/cache && \
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache /var/www/html/public && \
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Copy Supervisor configuration
COPY ./supervisord.conf /etc/supervisor/supervisord.conf

# Copy Nginx configuration
COPY ./nginx.conf /etc/nginx/nginx.conf

# Copy and set up entrypoint script
COPY ./docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose HTTP port
EXPOSE 80

# Stay as root to run supervisord (it will manage user permissions for child processes)
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
