FROM php:apache
FROM php:7.4-cli

RUN apt-get update \
 && apt-get install -y --no-install-recommends git unzip libzip-dev \
 && docker-php-ext-install zip \
 && rm -rf /var/lib/apt/lists/*

# system deps as needed...
# RUN apt-get update && apt-get install -y libzip-dev && docker-php-ext-install zip pdo_mysql

WORKDIR /app
COPY composer.json composer.lock ./

RUN apt-get update && apt-get install -y zip libzip-dev libpng-dev \
    && docker-php-ext-install pdo_mysql gd zip \
    && rm -rf /var/lib/apt/lists/*

RUN php -r "copy('https://getcomposer.org/installer','composer-setup.php');" \
 && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
 && rm composer-setup.php

# Composer installation.
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN sed -i 's/"LaravelCollective\/html"/"laravelcollective\/html"/g' composer.json \
    && sed -i 's/"laravelCollective\/html"/"laravelcollective\/html"/g' composer.json

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress
ENV PATH="${PATH}:/root/.composer/vendor/bin"

COPY . /var/www/html/

# Authorize these folders to be edited
RUN chmod -R 777 /var/www/html/storage
RUN chmod -R 777 /var/www/html/bootstrap/cache

# Allow rewrite
RUN a2enmod rewrite
