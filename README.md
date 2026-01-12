# Invoice Ninja Docker Setup

A standalone Docker setup for Invoice Ninja with Nginx and Supervisor.

## Quick Start

1. **Copy the environment file and configure it:**
   ```bash
   cp .env.example .env
   ```

2. **Generate a new APP_KEY:**
   First start the containers temporarily to generate the key:
   ```bash
   docker compose up -d
   docker exec invoiceninja php /var/www/html/artisan key:generate --show
   ```
   Copy the generated key and add it to your `.env` file as `APP_KEY=base64:...`

3. **Edit `.env` with your settings:**
   - Set `APP_URL` to your domain
   - Set the generated `APP_KEY`
   - Configure mail settings
   - Set initial admin credentials (`IN_USER_EMAIL` and `IN_PASSWORD`)

4. **Rebuild and start the containers:**
   ```bash
   docker compose down -v
   docker compose up -d
   ```

5. **Access Invoice Ninja:**
   - Default: http://localhost:7077
   - Login with the credentials you set in `.env`

## Services

- **invoiceninja**: Main application container (PHP-FPM + Nginx + Queue Worker)
- **ninjadb**: MySQL 8 database

## Volumes

- `app_data_invoiceninja`: Application data and storage
- `db_data_invoiceninja`: MySQL database files

## Configuration Files

- `Dockerfile`: Builds the Invoice Ninja container with Nginx and Supervisor
- `docker-compose.yml`: Orchestrates the services
- `nginx.conf`: Nginx web server configuration
- `supervisord.conf`: Supervisor process manager configuration
- `docker-entrypoint.sh`: Container initialization script
- `plugins/`: Custom blade templates and HTML files

## Customization

### Plugins Directory

The `plugins/` folder contains custom files that are mounted into the container:
- `index.blade.php`: Custom React view template
- `settoken.html`: Token setting utility

### Environment Variables

Key environment variables in `.env`:

| Variable | Description |
|----------|-------------|
| `APP_URL` | Your Invoice Ninja URL |
| `APP_KEY` | Laravel application key |
| `DB_HOST` | Database hostname (default: ninjadb) |
| `DB_DATABASE` | Database name |
| `DB_USERNAME` | Database user |
| `DB_PASSWORD` | Database password |
| `MAIL_*` | SMTP mail configuration |

## Maintenance

### View logs
```bash
docker compose logs -f invoiceninja
```

### Access container shell
```bash
docker compose exec invoiceninja bash
```

### Run artisan commands
```bash
docker compose exec invoiceninja php /var/www/app/artisan <command>
```

### Backup database
```bash
docker compose exec ninjadb mysqldump -u ninja -pninja ninja > backup.sql
```

## Stopping

```bash
docker compose down
```

To remove volumes as well:
```bash
docker compose down -v
```
