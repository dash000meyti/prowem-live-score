# syntax=docker/dockerfile:1.7

FROM php:8.3-fpm-bookworm AS php-base

ARG PHPREDIS_VERSION=6.2.0

WORKDIR /var/www/html

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        git \
        libicu-dev \
        libpq-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-install -j"$(nproc)" \
        bcmath \
        intl \
        opcache \
        pcntl \
        pdo_pgsql \
        zip \
    && git clone --depth 1 --branch "${PHPREDIS_VERSION}" https://github.com/phpredis/phpredis.git /usr/src/php/ext/redis \
    && docker-php-ext-install -j"$(nproc)" redis \
    && rm -rf /usr/src/php/ext/redis /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

FROM php-base AS development

COPY composer.json composer.lock ./
RUN composer install \
    --no-autoloader \
    --no-interaction \
    --no-scripts \
    --prefer-dist

COPY . .

RUN composer dump-autoload --optimize \
    && chown -R www-data:www-data storage bootstrap/cache

FROM php-base AS production-dependencies

COPY composer.json composer.lock ./
RUN composer install \
    --classmap-authoritative \
    --no-dev \
    --no-interaction \
    --no-progress \
    --no-scripts \
    --prefer-dist

COPY . .

RUN composer dump-autoload --classmap-authoritative --no-dev \
    && rm -rf tests

FROM php-base AS production

ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stderr \
    LOG_LEVEL=warning

COPY docker/php/conf.d/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY --from=production-dependencies --chown=www-data:www-data /var/www/html /var/www/html

RUN mkdir -p \
        storage/framework/cache/data \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
    && chown -R www-data:www-data storage bootstrap/cache

CMD ["php-fpm"]
