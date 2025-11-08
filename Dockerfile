FROM php:8.3-apache

# --- Install dependencies ---
RUN apt-get update && apt-get install -y \
  git unzip libpng-dev libjpeg-dev libfreetype6-dev libxml2-dev libzip-dev libicu-dev ghostscript \
  libonig-dev libcurl4-openssl-dev libxslt1-dev libmagickwand-dev supervisor vim \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install gd mysqli zip intl opcache soap xsl xml mbstring curl exif pdo pdo_mysql \
  && rm -rf /var/lib/apt/lists/*

# --- Enable Apache Rewrite module ---
RUN a2enmod rewrite

# --- PHP settings ---
RUN echo "upload_max_filesize=128M" > /usr/local/etc/php/conf.d/uploads.ini && \
  echo "post_max_size=128M" >> /usr/local/etc/php/conf.d/uploads.ini && \
  echo "max_input_vars=5000" >> /usr/local/etc/php/conf.d/uploads.ini && \
  echo "memory_limit=512M" >> /usr/local/etc/php/conf.d/uploads.ini

# --- Moodle setup ---
ENV MOODLE_VERSION=MOODLE_501_STABLE
WORKDIR /var/www/html

RUN git clone --branch ${MOODLE_VERSION} --depth 1 https://github.com/moodle/moodle.git . && \
  mkdir -p /var/www/moodledata && \
  chown -R www-data:www-data /var/www/html /var/www/moodledata

# --- Copy entrypoint and supervisor config ---
COPY entrypoint.sh /entrypoint.sh
COPY supervisord.conf /etc/supervisor/supervisord.conf
RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
