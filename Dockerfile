ARG REGISTRY_PREFIX=''
FROM ${REGISTRY_PREFIX}alpine:3.9
MAINTAINER David Marteau <david.marteau@3liz.com>
LABEL Description="Lizmap web client" Vendor="3liz.org"

ARG lizmap_version=master
ARG lizmap_git=https://github.com/3liz/lizmap-web-client.git

ARG lizmap_wps_version=master
ARG lizmap_wps_git=https://github.com/3liz/lizmap-wps-web-client-module.git 

RUN apk update && apk upgrade
RUN apk --no-cache add git php7 php7-fpm \
    php7-tokenizer \
    php7-opcache \
    php7-session \
    php7-iconv \
    php7-intl \
    php7-mbstring \
    php7-openssl \
    php7-fileinfo \
    php7-curl \
    php7-json \
    php7-redis \
    php7-pgsql \ 
    php7-sqlite3 \
    php7-gd \
    php7-dom \
    php7-xml \
    php7-xmlrpc \
    php7-xmlreader \
    php7-xmlwriter \
    php7-simplexml \
    php7-phar \
    php7-gettext \
    php7-ctype \
    php7-zip \
    php7-ldap

## Install lizmap web client
RUN echo "cloning $lizmap_version from $lizmap_git" \
    && git clone --branch $lizmap_version --depth=1  $lizmap_git lizmap-web-client \
    && rm -rf lizmap-web-client/vagrant lizmap-web-client/.git \
    && mv lizmap-web-client /www \
    && mv /www/lizmap/var/config /www/lizmap/var/config.dist \
    && mv /www/lizmap/www /www/lizmap/www.dist

# Install lizmap wps
RUN git clone --branch $lizmap_wps_version --depth=1 $lizmap_wps_git lizmap-wps \
    && mv lizmap-wps/wps /www/lizmap/lizmap-modules/wps \
    && rm -rf lizmap-wps

COPY factory.manifest /build.manifest
COPY lizmapConfig.ini.php.dist localconfig.ini.php.dist /www/lizmap/var/config.dist/
COPY lizmap-entrypoint.sh update-config.php /bin/ 
RUN chmod 755 /bin/lizmap-entrypoint.sh /bin/update-config.php

ENV PHP_INI_DIR /etc/php7

WORKDIR /www
ENTRYPOINT ["/bin/lizmap-entrypoint.sh"]
CMD ["/usr/sbin/php-fpm7", "-F", "-O"]




