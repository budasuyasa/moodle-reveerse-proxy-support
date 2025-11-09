#!/bin/bash
set -e

# --- Wait for Database ---
echo "⏳ Waiting for database ${MOODLE_DATABASE_HOST}:${MOODLE_DATABASE_PORT_NUMBER}..."
until nc -z -v -w30 "$MOODLE_DATABASE_HOST" "$MOODLE_DATABASE_PORT_NUMBER"; do
  echo "   Database not ready, retrying..."
  sleep 5
done
echo "✅ Database is ready."

# --- Generate config.php if not exists ---
if [ ! -f /var/www/html/config.php ]; then
  echo "🛠️ Generating config.php from template..."
  cp /var/www/html/config-dist.php /var/www/html/config.php

  sed -i "s|\$CFG->dbtype.*|\$CFG->dbtype    = '${MOODLE_DATABASE_TYPE}';|" /var/www/html/config.php
  sed -i "s|\$CFG->dbname.*|\$CFG->dbname    = '${MOODLE_DATABASE_NAME}';|" /var/www/html/config.php
  sed -i "s|\$CFG->dbuser.*|\$CFG->dbuser    = '${MOODLE_DATABASE_USER}';|" /var/www/html/config.php
  sed -i "s|\$CFG->dbpass.*|\$CFG->dbpass    = '${MOODLE_DATABASE_PASSWORD}';|" /var/www/html/config.php
  sed -i "s|\$CFG->dbhost.*|\$CFG->dbhost    = '${MOODLE_DATABASE_HOST}';|" /var/www/html/config.php

  sed -i "s|\$CFG->wwwroot.*|\$CFG->wwwroot  = 'https://${MOODLE_HOST}';|" /var/www/html/config.php
  sed -i "s|\$CFG->dataroot.*|\$CFG->dataroot = '/var/www/moodledata';|" /var/www/html/config.php
  sed -i "s|\$CFG->directorypermissions.*|\$CFG->directorypermissions = 0777;|" /var/www/html/config.php

  sed -i "/require_once/d" /var/www/html/config.php
  echo "\$CFG->reverseproxy = filter_var(getenv('MOODLE_REVERSEPROXY'), FILTER_VALIDATE_BOOLEAN);" >>/var/www/html/config.php
  echo "\$CFG->sslproxy = filter_var(getenv('MOODLE_SSLPROXY'), FILTER_VALIDATE_BOOLEAN);" >>/var/www/html/config.php
  echo "\$CFG->lang = '${MOODLE_LANG:-en}';" >>/var/www/html/config.php
  echo "require_once(__DIR__ . '/lib/setup.php');" >>/var/www/html/config.php

  chown www-data:www-data /var/www/html/config.php
fi

# --- Run Moodle install CLI if not installed ---
if [ ! -f /var/www/moodledata/.installed ]; then
  echo "🚀 Running Moodle CLI installation..."
  php admin/cli/install.php \
    --chmod=2777 \
    --lang=${MOODLE_LANG:-en} \
    --wwwroot=https://${MOODLE_HOST} \
    --dataroot=/var/www/moodledata \
    --dbtype=${MOODLE_DATABASE_TYPE} \
    --dbhost=${MOODLE_DATABASE_HOST} \
    --dbname=${MOODLE_DATABASE_NAME} \
    --dbuser=${MOODLE_DATABASE_USER} \
    --dbpass=${MOODLE_DATABASE_PASSWORD} \
    --fullname="${MOODLE_SITE_NAME:-Moodle Site}" \
    --shortname="${MOODLE_SITE_SHORTNAME:-Moodle}" \
    --adminuser=${MOODLE_USERNAME} \
    --adminpass=${MOODLE_PASSWORD} \
    --adminemail=${MOODLE_EMAIL} \
    --agree-license \
    --non-interactive || true

  touch /var/www/moodledata/.installed
fi

# --- Start supervisord (cron + apache) ---
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
