FROM php:8.4-fpm-alpine

WORKDIR /var/www/html

# Install dependencies for GD and other extensions
RUN apk add --no-cache \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
    icu-dev

# Configure and install PHP extensions
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp

RUN docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    gd \
    zip \
    intl \
    opcache

RUN docker-php-ext-enable \
    mysqli \
    pdo \
    pdo_mysql \
    gd \
    zip \
    intl \
    opcache

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# PHP production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Custom PHP configuration
RUN echo "opcache.enable=1" >> "$PHP_INI_DIR/conf.d/opcache.ini" && \
    echo "opcache.memory_consumption=128" >> "$PHP_INI_DIR/conf.d/opcache.ini" && \
    echo "opcache.interned_strings_buffer=8" >> "$PHP_INI_DIR/conf.d/opcache.ini" && \
    echo "opcache.max_accelerated_files=4000" >> "$PHP_INI_DIR/conf.d/opcache.ini" && \
    echo "opcache.validate_timestamps=0" >> "$PHP_INI_DIR/conf.d/opcache.ini"

# Create www-data user if it doesn't exist (for permissions)
RUN addgroup -g 1000 -S www && \
    adduser -u 1000 -S www -G www

USER www

CMD ["php-fpm"]
