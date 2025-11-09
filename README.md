# Moodle Reverse Proxy Ready

## ✨ Fitur

- Mudah untuk dideploy, tinggal build dan run. TLRDR, hanya perlu `docker compose up -d`
- **Moodle 5.0.1** (MOODLE_501_STABLE branch), Anda bisa ganti versi moodle dengan yang Anda inginkan
- **PHP 8.3** dengan Apache
- **MariaDB 10.11** sebagai database (optional)
- **Reverse Proxy Ready** - Full support automatic HTTPS
- **Ghostscript** - Untuk PDF annotation support
- **Environment-based Configuration** - Mudah dikonfigurasi via `.env` file
- **Auto SSL Proxy Detection** - Mendukung X-Forwarded-Proto header
- **Optimized PHP Settings** - Pre-configured untuk performa optimal

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/budasuyasa/moodle-reveerse-proxy-support
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

### Deploy dengan Coolify

Anda menggunakan coolify? tambahkan container labels berikut pada service `moodle` untuk reverse proxy dan auto https:

```yaml

networks:
 - moodle_net
 - coolify

labels:
  - traefik.enable=true
  - traefik.docker.network=coolify
  - traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https
  - traefik.http.middlewares.gzip.compress=true
  - traefik.http.routers.moodle-http.entryPoints=http
  - traefik.http.routers.moodle-http.rule=Host(`your-domain.com`)
  - traefik.http.routers.moodle-http.middlewares=redirect-to-https
  - traefik.http.routers.moodle-https.entryPoints=https
  - traefik.http.routers.moodle-https.rule=Host(`your-domain.com`)
  - traefik.http.routers.moodle-https.middlewares=gzip
  - traefik.http.routers.moodle-https.tls.certresolver=letsencrypt
  - traefik.http.services.moodle.loadbalancer.server.port=80
```

Pastikan Anda juga menambahkan networks coolify:

```yaml
networks:
  moodle_net:
    driver: bridge
  coolify:
    external: true

```

Jangan lupa sesuaikan `your-domain.com` dengan domain Anda.

## 🤝 Contributing

Kontribusi selalu diterima! Silakan buat issue atau pull request.

## 📄 License

Project ini menggunakan Moodle yang dilisensikan under GPL v3. Lihat [Moodle License](https://docs.moodle.org/dev/License) untuk detail lebih lanjut.

## 👥 Maintainer

Project ini dirawat oleh Buda Suyasa (<budasuyasa@hookigroup.com>)
