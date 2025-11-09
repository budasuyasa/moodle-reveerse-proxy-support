#!/bin/bash
set -e

echo "⏳ Waiting for database ${MOODLE_DATABASE_HOST}:${MOODLE_DATABASE_PORT_NUMBER}..."
until nc -z -v -w30 "$MOODLE_DATABASE_HOST" "$MOODLE_DATABASE_PORT_NUMBER"; do
  echo "   Database not ready, retrying..."
  sleep 5
done
echo "✅ Database is ready."

# --- Pastikan permission awal aman ---
chown -R www-data:www-data /var/www/html /var/www/moodledata

# --- Jalankan instalasi hanya jika belum ada config.php ---
if [ ! -f /var/www/html/config.php ]; then
  echo "🚀 Installing Moodle..."
  php admin/cli/install.php \
    --lang=${MOODLE_LANG:-en} \
    --wwwroot=${MOODLE_HOST} \
    --dataroot=/var/www/moodledata \
    --dbtype=${MOODLE_DATABASE_TYPE:-mysql} \
    --dbhost=${MOODLE_DATABASE_HOST:-moodle-db} \
    --dbname=${MOODLE_DATABASE_NAME:-moodle} \
    --dbuser=${MOODLE_DATABASE_USER:-moodle} \
    --dbpass=${MOODLE_DATABASE_PASSWORD:-moodlepass} \
    --fullname="${MOODLE_SITE_NAME:-Moodle LMS}" \
    --shortname="${MOODLE_SITE_SHORTNAME:-Moodle}" \
    --adminuser=${MOODLE_USERNAME:-admin} \
    --adminpass=${MOODLE_PASSWORD:-Admin123} \
    --adminemail=${MOODLE_EMAIL:-admin@example.com} \
    --agree-license \
    --non-interactive || true

  echo "✅ Installation complete."
fi

# --- Pastikan file akhirnya dimiliki www-data ---
chown -R www-data:www-data /var/www/html /var/www/moodledata

# --- Jalankan supervisord (Apache + cron) ---
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
