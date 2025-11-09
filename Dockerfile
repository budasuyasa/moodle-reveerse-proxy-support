FROM php:8.3-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
  git unzip cron curl ghostscript libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
  libxml2-dev libicu-dev libzip-dev libldap2-dev libxslt-dev netcat-traditional \
  supervisor vim && \
  rm -rf /var/lib/apt/lists/*

# Enable Apache mods
RUN a2enmod rewrite headers ssl

# Configure PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
  docker-php-ext-install -j$(nproc) \
  gd intl mysqli opcache soap xml zip ldap xsl

# PHP settings
RUN echo "upload_max_filesize = 128M" > /usr/local/etc/php/conf.d/uploads.ini && \
  echo "post_max_size = 128M" >> /usr/local/etc/php/conf.d/uploads.ini && \
  echo "max_input_vars = 5000" >> /usr/local/etc/php/conf.d/uploads.ini && \
  echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/uploads.ini

WORKDIR /var/www/html

# Clone Moodle core (latest stable)
ARG MOODLE_VERSION=MOODLE_501_STABLE
RUN git clone -b ${MOODLE_VERSION} --depth=1 https://github.com/moodle/moodle.git /var/www/html

# --- Apache Config ---
RUN echo "<VirtualHost *:80>\n\
  ServerAdmin webmaster@localhost\n\
  DocumentRoot /var/www/html/public\n\
  <Directory /var/www/html/public>\n\
  Options Indexes FollowSymLinks\n\
  AllowOverride All\n\
  Require all granted\n\
  </Directory>\n\
  ErrorLog \${APACHE_LOG_DIR}/error.log\n\
  CustomLog \${APACHE_LOG_DIR}/access.log combined\n\
  </VirtualHost>" > /etc/apache2/sites-available/000-default.conf && \
  a2enmod rewrite headers ssl

# Create data directory
RUN mkdir -p /var/www/moodledata && chown -R www-data:www-data /var/www && chmod -R 775 /var/www

# Copy supervisor & entrypoint
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
