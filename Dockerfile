FROM php:7.4-cli

RUN apt-get update && apt-get install -y \
        git \
        libzip-dev \
        zip \
        unzip \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        supervisor \
        libmagickwand-dev libmagickcore-dev \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install \
        pdo_mysql \
        bcmath \
        zip \
        pcntl \
        sockets

RUN pecl install redis \
    && pecl install swoole-4.5.6 \
    && pecl install imagick \
    && docker-php-ext-enable redis swoole imagick

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/
COPY conf/php-user.ini $PHP_INI_DIR/conf.d/

COPY ./conf/supervisor/ /etc/supervisor/conf.d/

WORKDIR /var/www/html

CMD ["supervisord","-n"]