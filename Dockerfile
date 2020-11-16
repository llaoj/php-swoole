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
        libssl-dev \
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
    && pecl install imagick \
    && docker-php-ext-enable redis imagick

RUN curl -fsSL 'https://github.com/swoole/swoole-src/archive/v4.5.2.tar.gz' -o swoole.tar.gz \
    && mkdir -p /tmp/swoole \
    && tar -xf swoole.tar.gz -C /tmp/swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && docker-php-ext-configure /tmp/swoole --enable-openssl --enable-http2 --enable-sockets --enable-mysqlnd \
    && docker-php-ext-install /tmp/swoole \
    && rm -r /tmp/swoole

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && mv ./conf/php-user.ini $PHP_INI_DIR/conf.d/ \
    && echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

ADD ./conf/supervisor/ /etc/supervisor/conf.d/

WORKDIR /var/www/html

CMD ["supervisord","-n"]