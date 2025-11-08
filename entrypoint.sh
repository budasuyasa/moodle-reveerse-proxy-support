# --- Generate Moodle config-env.php from ENV ---
CONFIG_ENV_FILE="/var/www/html/config-env.php"
CONFIG_FILE="/var/www/html/config.php"

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
fi

# --- Main config.php (acts as loader) ---
if [ ! -f "$CONFIG_FILE" ]; then
  cat <<EOF >"$CONFIG_FILE"
<?php
if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    \$_SERVER['HTTPS'] = 'on';
}

require_once(__DIR__ . '/config-env.php');
EOF
fi
