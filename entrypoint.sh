#!/bin/bash
set -e

MOODLE_ROOT="/var/www/html"
MOODLE_DATA="/var/www/moodledata"
CONFIG_FILE="$MOODLE_ROOT/config.php"
INSTALLED_FLAG="$MOODLE_DATA/.installed"

echo "🧩 Starting entrypoint..."

# --- Wait for Database ---
echo "⏳ Waiting for database ${MOODLE_DATABASE_HOST}:${MOODLE_DATABASE_PORT_NUMBER}..."
until nc -z "$MOODLE_DATABASE_HOST" "$MOODLE_DATABASE_PORT_NUMBER"; do
  echo "   Database not ready at ${MOODLE_DATABASE_HOST}:${MOODLE_DATABASE_PORT_NUMBER}, retrying..."
  sleep 5
done
echo "✅ Database is ready."

# helper: inject reverseproxy/sslproxy/lang into config (idempotent)
inject_proxy_flags() {
  local cfg="$1"
  # remove previously appended lines if present to avoid duplicates
  sed -i "/^\\\$CFG->reverseproxy/d" "$cfg" || true
  sed -i "/^\\\$CFG->sslproxy/d" "$cfg" || true
  sed -i "/^\\\$CFG->lang/d" "$cfg" || true

  # insert before last require_once (if exists) otherwise append
  if grep -q "require_once(.*/lib/setup.php" "$cfg"; then
    # insert lines before the require_once line
    awk -v rp="\\\$CFG->reverseproxy = filter_var(getenv('MOODLE_REVERSEPROXY'), FILTER_VALIDATE_BOOLEAN);" \
      -v sp="\\\$CFG->sslproxy = filter_var(getenv('MOODLE_SSLPROXY'), FILTER_VALIDATE_BOOLEAN);" \
      -v lg="\\\$CFG->lang = '${MOODLE_LANG:-en}';" \
      '{
          if ($0 ~ /require_once\(.+lib\/setup.php/) {
            print rp;
            print sp;
            print lg;
          }
          print $0;
        }' "$cfg" >"$cfg.tmp" && mv "$cfg.tmp" "$cfg"
  else
    # just append (safe fallback)
    echo "\$CFG->reverseproxy = filter_var(getenv('MOODLE_REVERSEPROXY'), FILTER_VALIDATE_BOOLEAN);" >>"$cfg"
    echo "\$CFG->sslproxy = filter_var(getenv('MOODLE_SSLPROXY'), FILTER_VALIDATE_BOOLEAN);" >>"$cfg"
    echo "\$CFG->lang = '${MOODLE_LANG:-en}';" >>"$cfg"
    echo "require_once(__DIR__ . '/lib/setup.php');" >>"$cfg"
  fi

  chown www-data:www-data "$cfg"
}

# ---------------------------
# CASE A: config.php does NOT exist -> run install.php (creates config.php)
# ---------------------------
if [ ! -f "$CONFIG_FILE" ]; then
  echo "🛠️ config.php not found — running admin/cli/install.php to create config and DB..."

  php "$MOODLE_ROOT/admin/cli/install.php" \
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
    --shortname="${MOODLE_SITE_SHORTNAME:-Moodle}" \
    --adminuser=${MOODLE_USERNAME:-admin} \
    --adminpass=${MOODLE_PASSWORD:-admin123} \
    --adminemail=${MOODLE_EMAIL:-admin@example.com} \
    --agree-license \
    --non-interactive

  # after install.php, config.php should exist now
  if [ -f "$CONFIG_FILE" ]; then
    echo "✅ install.php created config.php — injecting reverseproxy flags"
    inject_proxy_flags "$CONFIG_FILE"
    touch "$INSTALLED_FLAG"
  else
    echo "❌ install.php did not create config.php — check logs"
  fi

# ---------------------------
# CASE B: config.php exists but moodledata .installed flag missing -> run install_database.php
# ---------------------------
elif [ -f "$CONFIG_FILE" ] && [ ! -f "$INSTALLED_FLAG" ]; then
  echo "⚙️ config.php exists but site not marked installed. Running admin/cli/install_database.php ..."

  # ensure config.php has proxy flags before DB install (so install_database honors reverseproxy)
  inject_proxy_flags "$CONFIG_FILE"

  php "$MOODLE_ROOT/admin/cli/install_database.php" \
    --dbtype=${MOODLE_DATABASE_TYPE:-mysqli} \
    --dbhost=${MOODLE_DATABASE_HOST:-mariadb} \
    --dbname=${MOODLE_DATABASE_NAME:-moodle} \
    --dbuser=${MOODLE_DATABASE_USER:-moodle} \
    --dbpass=${MOODLE_DATABASE_PASSWORD:-moodle} \
    --adminuser=${MOODLE_USERNAME:-admin} \
    --adminpass=${MOODLE_PASSWORD:-admin123} \
    --adminemail=${MOODLE_EMAIL:-admin@example.com} \
    --agree-license \
    --non-interactive

  # if install_database completed, create installed flag
  if [ $? -eq 0 ]; then
    echo "✅ install_database.php completed"
    touch "$INSTALLED_FLAG"
  else
    echo "❌ install_database.php failed — check output above"
  fi

else
  echo "ℹ️ config.php already exists and site appears installed (or .installed present). Skipping install steps."
fi

# make sure moodledata ownership and perms are correct
chown -R www-data:www-data "$MOODLE_DATA"
chmod -R 0775 "$MOODLE_DATA" || true

# --- Start supervisord (cron + apache) ---
echo "🧭 Starting supervisord..."
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
