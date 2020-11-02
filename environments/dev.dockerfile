ARG XDEBUG_VERSION
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini" \
    && mkdir -p /usr/src/php/ext/xdebug \
    && curl -fsSL https://pecl.php.net/get/xdebug-${XDEBUG_VERSION}.tgz | tar xvz -C "/usr/src/php/ext/xdebug" --strip 1 \
    && docker-php-ext-install xdebug \
    && docker-php-source delete

COPY environments/dev.ini "$PHP_INI_DIR/conf.d/00-development.ini"

EXPOSE 9003
