ARG PHP_VERSION
FROM php:${PHP_VERSION}-fpm-alpine

ARG COMPOSER_VERSION
RUN set -e && \
    apk upgrade --update-cache --available \
    && apk add \
            bash \
            shadow \
    && usermod -u 1000 www-data && groupmod -g 1000 www-data \
    && apk del shadow \
    && rm -rf /var/cache/apk/*

ARG COMPOSER_VERSION
RUN curl -sS https://getcomposer.org/installer | php -- \
            --install-dir=/usr/local/bin \
            --version=${COMPOSER_VERSION} \
            --filename=composer

%%ENVIRONMENT%%

WORKDIR /var/www

EXPOSE 9000