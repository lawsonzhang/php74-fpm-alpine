FROM php:7.4.11-fpm-alpine

RUN apk update; \
    apk add tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone; \
    apk del tzdata; \
    \
    addgroup -g 88888 -S yiibool; \
    adduser -u 88888 -h /home/yiibool -S -G yiibool yiibool

ENV PHPIZE_DEPS \
    autoconf \
    libc-dev \
    gcc \
    g++ \
    make

RUN set -e; \
    \
    apk add --no-cache --virtual .runtime-deps \
        libjpeg \
        libpng \
        freetype \
        libmemcached-libs \
        libmcrypt \
        git \
        nginx \
        supervisor \
        busybox-extras \
        imagemagick-dev \
    ; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        libjpeg-turbo-dev \
        libpng-dev \
        freetype-dev \
        libxml2-dev \
        libzip-dev \
        openssl libssh-dev \
        libmemcached-dev \
        libmcrypt-dev \
    ;\
    docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
        mysqli \
        pdo_mysql \
        zip bcmath \
        opcache \
        pcntl \
        soap \
    && pecl install redis \
    && pecl install imagick \
    && cd /tmp && pecl download swoole \
    && tar -zxvf swoole* && cd swoole* \
    && phpize \
    && ./configure --enable-openssl --enable-http2 \
    && make -j "$(nproc)" && make install \
    && cd ~ && rm -rf /tmp/swoole* \
    && docker-php-ext-enable gd mysqli pdo_mysql zip bcmath opcache pcntl soap imagick redis swoole; \
    apk del .build-deps

RUN mkdir -p /data/logs/php \
    && mkdir -p /data/logs/nginx

COPY php.ini /usr/local/etc/php/
COPY php-fpm.conf /usr/local/etc/php-fpm.conf
COPY php-fpm.d /usr/local/etc/php-fpm.d
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d /etc/nginx/conf.d
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
