FROM php:8.5-fpm-alpine3.22

ARG UID
ARG GID

ENV UID=${UID}
ENV GID=${GID}

RUN mkdir -p /var/www/html

WORKDIR /var/www/html

RUN addgroup -S -g ${GID} app-runner
RUN adduser -G app-runner --system -D -s /bin/sh -u ${UID} app-runner

RUN sed -i "s/user = www-data/user = app-runner/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/group = www-data/group = app-runner/g" /usr/local/etc/php-fpm.d/www.conf
RUN sed -i "s/listen.owner = www-data/listen.owner = app-runner/g" /usr/local/etc/php-fpm.d/www.conf

RUN echo "php_admin_flag[log_errors] = on" >> /usr/local/etc/php-fpm.d/www.conf

# Install dependencies for GD
RUN apk add --no-cache \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev

# Configure and install GD extension
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp

RUN docker-php-ext-install mysqli pdo pdo_mysql gd
RUN docker-php-ext-enable mysqli pdo pdo_mysql gd

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER app-runner

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm", "-y", "/usr/local/etc/php-fpm.conf", "-R"]
