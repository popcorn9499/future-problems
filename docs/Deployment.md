# Deployment

GoBison is hosted at [gobison.popicraft.net](https://gobison.popicraft.net) on a Hetzner VPS.

Test site hosted at [test.gobison.popicraft.net](https://test.gobison.popicraft.net) now live

## Server environment

| Component | Version / purpose |
| --- | --- |
| Ubuntu | 24.04 |
| Java | 21, for the backend |
| PostgreSQL | Application database |
| Docker | Used to run PostgreSQL |
| Apache | Serves the Flutter web app and proxies API requests |

## Local development

Install Java 21, Flutter 3.47.7 (stable), and PostgreSQL. The database schema must already exist; Hibernate validates it rather than creating it.

1. Copy `backend/local.properties.example` to `backend/local.properties`. Set `SUPABASE_DB_URL`, `SUPABASE_DB_USERNAME`, and `SUPABASE_DB_PASSWORD` for your PostgreSQL database, and set `MAIL_PASSWORD` to the Gmail SMTP app password. This file is git-ignored; do not commit credentials.
2. Build the backend JAR:

   ```sh
   cd backend
   ./mvnw --batch-mode package
   ```

3. Run the JAR in a separate terminal. The local backend listens on port 8080 by default:

   ```sh
   cd backend
   java -jar target/backend-0.0.1-SNAPSHOT.jar
   ```

4. Run the Flutter web app in another terminal:

   ```sh
   cd frontend
   flutter pub get
   flutter run -d chrome --web-port=3000
   ```

The frontend uses `http://localhost:8080` as its default API URL. Override it with `--dart-define=API_BASE_URL=<url>` if needed.

## CI and production deployment

GitHub Actions runs backend verification and Flutter analysis/tests on pushes and pull requests. CI uses Java 21, PostgreSQL 17, and Flutter 3.47.7 stable.

The deployment workflows run after successful CI on `master` and `dev`. Configure the `DEPLOY_SSH_KEY` GitHub Actions secret with the private key for `deploybot` on `popicraft.net` (SSH port 2525). The deploy account must be able to write to both deployment directories and restart both backend systemd services.

| Workflow | `master` deployment | `dev` deployment |
| --- | --- | --- |
| Backend | Uploads the JAR to `/home/deploybot/gobison-backend/backend.jar`; restarts `gobison-backend.service` (port 3000). | Uploads the JAR to `/home/deploybot/gobison-backend-dev/backend.jar`; restarts `gobison-backend-dev.service` (configure it to listen on port 3001). |
| Frontend | Builds with `API_BASE_URL=https://gobison.popicraft.net`; syncs to `/var/www/gobison/`. | Builds with `API_BASE_URL=https://test.gobison.popicraft.net`; syncs to `/var/www/test.gobison/`. |

Provision the dev systemd service and web-server virtual host separately: `test.gobison.popicraft.net` must serve `/var/www/test.gobison/` and proxy API requests to the dev backend on port 3001. The workflows deploy files and restart services; they do not configure the server or DNS.

The backend service reads database and mail settings from `local.properties` in its working directory. Keep the production file at `/home/deploybot/gobison-backend/local.properties`; deployment replaces only the JAR. The database credentials used in CI are for its temporary test database, not production.

### Backend systemd service

Save the following as `/etc/systemd/system/gobison-backend.service`:

```ini
[Unit]
Description=GoBison Spring Boot Backend Service
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
User=deploybot
Group=deploybot
WorkingDirectory=/home/deploybot/gobison-backend
ExecStart=/usr/bin/java -jar /home/deploybot/gobison-backend/backend.jar --server.port=3000
SuccessExitStatus=143
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable the service:

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now gobison-backend
```

Allow `deploybot` to run `sudo systemctl restart gobison-backend` without a password so the deployment workflow can restart the service.

### Apache HTTPS virtual host

Save this as `/etc/apache2/sites-available/gobison.conf`. It serves the Flutter build from `/var/www/gobison` and proxies `/api/` requests to the backend on port 3000:

```apache
<IfModule mod_ssl.c>
  <VirtualHost *:443>
    ServerName gobison.popicraft.net

    SSLCertificateFile /etc/letsencrypt/live/popicraft.net-0001/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/popicraft.net-0001/privkey.pem
    Include /etc/letsencrypt/options-ssl-apache.conf

    DocumentRoot /var/www/gobison
    ProxyPreserveHost On

    ProxyPass /api/ http://localhost:3000/api/
    ProxyPassReverse /api/ http://localhost:3000/api/

    RequestHeader set X-Forwarded-Host "gobison.popicraft.net"
  </VirtualHost>
</IfModule>
```

Enable the required modules and site, then check and reload Apache:

```sh
sudo a2enmod ssl proxy proxy_http headers
sudo a2ensite gobison.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

Confirm the certificate files exist and Apache can read them. Apache must serve the deployed Flutter files, and the production frontend API URL should remain `https://gobison.popicraft.net`.

## Run CI checks locally

```sh
(cd backend && ./mvnw --batch-mode verify)
(cd frontend && flutter pub get && flutter analyze --no-fatal-infos && flutter test --coverage)
```

## Design choices

We decided against running the backend and frontend in a docker container as it felt like extra overhead for the backend which is just running a java file.
As well for frontend we just need a server to serve files over http and a ssl certificate which was already preconfigured to some extent.
