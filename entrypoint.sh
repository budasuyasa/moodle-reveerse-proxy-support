#!/bin/bash
set -e

MOODLE_PATH="/var/www/html"
MOODLE_DATA=${MOODLE_DATA:-/var/www/moodledata}
CONFIG_FILE="$MOODLE_PATH/config.php"
CONFIG_ENV_FILE="$MOODLE_PATH/config-env.php"
INSTALLED_FLAG="$MOODLE_DATA/.moodle_installed"

echo "🧩 Starting Moodle container setup..."

# --- Wait for Database ---
echo "⏳ Waiting for database to be ready..."
until nc -z -v -w30 "$MOODLE_DATABASE_HOST" "$MOODLE_DATABASE_PORT_NUMBER"; do
  echo "⏳ Database not ready at ${MOODLE_DATABASE_HOST}:${MOODLE_DATABASE_PORT_NUMBER}, retrying..."
  sleep 5
done
echo "✅ Database is ready!"

# --- Generate Moodle config-env.php ---
if [ ! -f "$CONFIG_ENV_FILE" ]; then
  echo "🧩 Generating config-env.php from environment..."
  cat <<EOF >"$CONFIG_ENV_FILE"
<?php
\$CFG = new stdClass();

\$CFG->dbtype    = getenv('MOODLE_DATABASE_TYPE') ?: 'mysqli';
\$CFG->dblibrary = 'native';
\$CFG->dbhost    = getenv('MOODLE_DATABASE_HOST') ?: 'mariadb';
\$CFG->dbname    = getenv('MOODLE_DATABASE_NAME') ?: 'moodle';
\$CFG->dbuser    = getenv('MOODLE_DATABASE_USER') ?: 'moodle';
\$CFG->dbpass    = getenv('MOODLE_DATABASE_PASSWORD') ?: 'moodle';
\$CFG->prefix    = 'mdl_';

\$CFG->wwwroot   = 'https://' . getenv('MOODLE_HOST');
\$CFG->dataroot  = getenv('MOODLE_DATA') ?: '/var/www/moodledata';
\$CFG->admin     = 'admin';
\$CFG->directorypermissions = 0777;

\$CFG->reverseproxy = filter_var(getenv('MOODLE_REVERSEPROXY'), FILTER_VALIDATE_BOOLEAN);
\$CFG->sslproxy     = filter_var(getenv('MOODLE_SSLPROXY'), FILTER_VALIDATE_BOOLEAN);

require_once(__DIR__ . '/lib/setup.php');
EOF
else
  echo "✅ config-env.php already exists, skipping generation."
fi

# --- Generate main config.php (Loader only) ---
if [ ! -f "$CONFIG_FILE" ]; then
  echo "🧩 Creating config.php loader..."
  cat <<EOF >"$CONFIG_FILE"
<?php
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    \$_SERVER['HTTPS'] = 'on';
}
require_once(__DIR__ . '/config-env.php');
EOF
else
  echo "✅ config.php already exists, skipping generation."
fi

# --- Run Moodle installation via CLI if not installed ---
if [ ! -f "$INSTALLED_FLAG" ]; then
  echo "🚀 Installing Moodle via CLI..."
  php "$MOODLE_PATH/admin/cli/install.php" \
    --chmod=2777 \
    --lang=${MOODLE_LANG:-en} \
    --wwwroot="https://${MOODLE_HOST}" \
    --dataroot="${MOODLE_DATA}" \
    --dbtype=${MOODLE_DATABASE_TYPE:-mysqli} \
    --dbhost=${MOODLE_DATABASE_HOST:-mariadb} \
    --dbname=${MOODLE_DATABASE_NAME:-moodle} \
    --dbuser=${MOODLE_DATABASE_USER:-moodle} \
    --dbpass=${MOODLE_DATABASE_PASSWORD:-moodle} \
    --fullname="${MOODLE_SITE_NAME:-Moodle Site}" \
    --shortname="${MOODLE_SITE_NAME:-Moodle}" \
    --adminuser=${MOODLE_USERNAME:-admin} \
    --adminpass=${MOODLE_PASSWORD:-admin123} \
    --adminemail=${MOODLE_EMAIL:-admin@example.com} \
    --agree-license \
    --non-interactive || true

  touch "$INSTALLED_FLAG"
  echo "✅ Moodle installed successfully!"
else
  echo "✅ Moodle already installed, skipping CLI installation."
fi

# --- Run cron via supervisor if configured ---
if [ -x "/usr/bin/supervisord" ]; then
  echo "🧭 Starting supervisor..."
  exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
else
  echo "🧭 Starting Apache/PHP-FPM..."
  exec "$@"
fi
