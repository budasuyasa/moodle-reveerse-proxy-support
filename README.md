# Moodle Reverse Proxy Support

Docker image untuk Moodle. Dengan versi yang bisa dikonfigurasi dan dilengkapi dukungan reverse proxy. Menggunakan `php8.3-apache` sebagai base image dan
Moodle versi `501 STABLE`.

## ✨ Fitur

- Mudah untuk dideploy, tinggal build dan run. TL;RDR;  `docker compose up -d`
- **Moodle 5.0.1** (`MOODLE_501_STABLE` branch), bisa disesuaikan dengan branch 501+.
- **Environment-based Configuration** - Mudah disesuaikan via `.env` file
- **Auto SSL Proxy Detection** - Mendukung X-Forwarded-Proto header
- **Optimized PHP Settings** - Pre-configured untuk performa optimal
- **Auto install** - Proses instalasi otomatis via `admin/cli/install.php`. Tidak perlu melakukan instalasi manual via web UI. Cukup mendefinisikan konfigurasi pada `.env`.

## 🚀 Quick Start

Buat sebuah docker-compose.yml dengan isi sebagai berikut:

```
services:
  moodle:
    image: ghcr.io/budasuyasa/moodle-reverse-proxy:main
    restart: always
    ports:
      - 8989:80
    environment:
      MOODLE_SITE_NAME="Moodle Learning Platform"
      MOODLE_SITE_SHORTNAME=Moodle
      MOODLE_HOST="http://localhost:8989"
      MOODLE_LANG=id
      MOODLE_REVERSEPROXY=false
      MOODLE_SSLPROXY=false
      MOODLE_USERNAME=admin
      MOODLE_PASSWORD=SuperSecret123
      MOODLE_EMAIL=admin@example.com
      MOODLE_DATABASE_TYPE=mariadb
      MOODLE_DATABASE_HOST=mariadb
      MOODLE_DATABASE_PORT_NUMBER=3306
      MOODLE_DATABASE_NAME=moodle
      MOODLE_DATABASE_USER=moodle
      MOODLE_DATABASE_PASSWORD=moodlepass
    volumes:
      - moodle_data:/var/www/moodledata
      - moodle_html:/var/www/html
    networks:
      - moodle_net

  mariadb:
    image: mariadb:10.11
    container_name: moodle-db
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: moodlepass
      MYSQL_DATABASE: moodle
      MYSQL_USER: moodle
      MYSQL_PASSWORD: moodlepass
    command: --max_allowed_packet=256M --innodb_buffer_pool_size=512M
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - moodle_net

volumes:
  moodle_html:
  moodle_data:
  mariadb_data:

networks:
  moodle_net:
    driver: bridge
```

Kemudian jalankan docker compose:

```
docker compose up -d
```

Tunggu hingga proses instalasi selesai. Cek proses installasi dengan memantau log container.

```
docker logs moodle -f
```

## 🏗️ Customize & Build Sendiri

### 1. Clone Repository

```bash
git clone https://github.com/budasuyasa/moodle-reverse-proxy-support
cd moodle-reverse-proxy-support
```

### 2. Setup Environment Variables

```bash
cp .env.example .env
```

Edit file `.env` dan sesuaikan dengan kebutuhan Anda:

Berikut adalah environment variables yang tersedia:

#### Moodle Site Configuration

| Variable | Default | Deskripsi |
|----------|---------|-----------|
| `MOODLE_VERSION` | `MOODLE_501_STABLE` | Moodle branch version, kunjungin repository Moodle untuk mendapatkan nama branch lainnya|
| `MOODLE_SITE_VERSION` | `My Moodle` | shortname site moodle|
| `MOODLE_SITE_NAME` | `Moodle Site` | Nama site Moodle |
| `MOODLE_HOST` | `localhost` | Domain/hostname untuk Moodle |
| `MOODLE_LANG` | `id` | Default language |
| `MOODLE_REVERSEPROXY` | `true` | Enable reverse proxy mode |
| `MOODLE_SSLPROXY` | `true` | Enable SSL proxy detection |

#### Database Configuration

| Variable | Default | Deskripsi |
|----------|---------|-----------|
| `MOODLE_DATABASE_TYPE` | `mysqli` | Database type (mariadb/mysqli/pgsql) |
| `MOODLE_DATABASE_HOST` | `mariadb` | Database hostname |
| `MOODLE_DATABASE_PORT_NUMBER` | `3306` | Database port |
| `MOODLE_DATABASE_NAME` | `moodle` | Database name |
| `MOODLE_DATABASE_USER` | `moodle` | Database username |
| `MOODLE_DATABASE_PASSWORD` | `moodle` | Database password |

#### Admin settings

| Variable | Default | Deskripsi |
|----------|---------|-----------|
| `MOODLE_USERNAME` | `admin` | username admin |
| `MOODLE_PASSWORD` | `SuperSecret123` | password admin |
| `MOODLE_EMAIL` | `admin@example.com` | email admin |

### 3. Build & Run

```bash

# Run services, sesuaikan docker-compose.yml jika diperlukan
docker compose up -d

```

Setelah container berjalan, proses instalasi akan otomatis dilakukan. Pantau proses instalasi,
pastikan tidak ada error dari moodle CLI installer.

```bash
docker logs moodle -f
```

`entrypoint.sh` akan melakukan instalasi dengan memastikan database siap terlebih dahulu.
Jangan panik jika log terlihat seperti ini:

```bash
⏳ Waiting for database mariadb:3306...
DNS fwd/rev mismatch: mariadb != moodle-db.moodle-reverse-proxy_moodle_net
mariadb [192.168.128.2] 3306 (mysql) : Connection refused
   Database not ready, retrying...
DNS fwd/rev mismatch: mariadb != moodle-db.moodle-reverse-proxy_moodle_net
mariadb [192.168.128.2] 3306 (mysql) : Connection refused
   Database not ready, retrying...
DNS fwd/rev mismatch: mariadb != moodle-db.moodle-reverse-proxy_moodle_net
mariadb [192.168.128.2] 3306 (mysql) open
✅ Database is ready.

```

Log di atas normal. Tunggu beberapa saat sampai database siap:

```
✅ Database is ready.
🚀 Installing Moodle...
                                 .-..-.
   _____                         | || |
  /____/-.---_  .---.  .---.  .-.| || | .---.
  | |  _   _  |/  _  \/  _  \/  _  || |/  __ \
  * | | | | | || |_| || |_| || |_| || || |___/
    |_| |_| |_|\_____/\_____/\_____||_|\_____)

Program pemasangan baris perintah Moodle 5.1+ (Build: 20251107)
-->Sistem
++ install.xml: Berhasil (11,32 detik) ++
++ xmldb_main_install: Berhasil (7,16 detik) ++
++ external_update_descriptions: Berhasil (2,97 detik) ++
```

Ini artinya instalasi sedang berjalan dan tunggu hingga selesai.

### Deploy dengan Coolify

Anda menggunakan coolify? tambahkan container labels berikut pada service `moodle` untuk reverse proxy dan auto https:

```yaml

networks:
 - moodle_net
 - coolify

labels:
  traefik.enable: "true"
  traefik.docker.network: "coolify"
  traefik.http.middlewares.redirect-to-https.redirectscheme.scheme: "https"
  traefik.http.middlewares.gzip.compress: "true"
  traefik.http.routers.moodle-http.entryPoints: "http"
  traefik.http.routers.moodle-http.rule: "Host(`yourdomain.com`)"
  traefik.http.routers.moodle-http.middlewares: "redirect-to-https"
  traefik.http.routers.moodle-https.entryPoints: "https"
  traefik.http.routers.moodle-https.rule: "Host(`yourdomain.com`)"
  traefik.http.routers.moodle-https.middlewares: "gzip"
  traefik.http.routers.moodle-https.tls.certresolver: "letsencrypt"
  traefik.http.services.moodle.loadbalancer.server.port: "80"
```

Jangan lupa sesuaikan `your-domain.com` dengan domain Anda.

Pastikan Anda juga menambahkan networks `coolify`:

```yaml
networks:
  moodle_net:
    driver: bridge
  coolify:
    external: true

```

Terakhir, set `MOODLE_REVERSEPROXY=false` karena sudah dihandle oleh traefik.

## Deploy dengan Nginx

```nginx

server {
    listen 80;
    server_name yourdomain.com;

    location / {
        proxy_pass http://localhost:8989;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
        client_max_body_size 128M;
    }

    access_log /var/log/nginx/moodle_access.log;
    error_log /var/log/nginx/moodle_error.log;
}
```

Terakhir gunaakan Letsencrypt untuk mendapatkan SSL certificate.

## 🤝 Contributing

Kontribusi selalu diterima! Silakan buat issue atau pull request.

## 📄 License

Project ini menggunakan Moodle yang dilisensikan under GPL v3. Lihat [Moodle License](https://docs.moodle.org/dev/License) untuk detail lebih lanjut.

## 👥 Maintainer

Project ini dirawat oleh Buda Suyasa (<budasuyasa@hookigroup.com>)
