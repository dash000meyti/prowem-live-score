FROM php:8.3-fpm-bookworm

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    libicu-dev \
    libzip-dev \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        intl \
        bcmath \
        zip \
        opcache \
        pcntl\
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock ./

RUN composer install \
    --no-interaction \
    --prefer-dist \
    --no-scripts \
    --no-autoloader

COPY . .

RUN composer dump-autoload --optimize \
    && chown -R www-data:www-data storage bootstrap/cache

CMD ["php-fpm"]
