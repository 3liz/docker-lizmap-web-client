ARG REGISTRY_PREFIX=''
FROM ${REGISTRY_PREFIX}php:7.2.16-fpm-alpine3.9
MAINTAINER David Marteau <david.marteau@3liz.com>
LABEL Description="Lizmap web client" Vendor="3liz.org"

ARG lizmap_version=master
ARG lizmap_git=https://github.com/3liz/lizmap-web-client.git

ARG lizmap_wps_version=master
ARG lizmap_wps_git=https://github.com/3liz/lizmap-wps-web-client-module.git 

# trust this project public key to trust the packages.
## NOTE: php.codecasts.rocks is no reliable (error 522)
## ADD https://php.codecasts.rocks/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

## RUN apk --no-cache add git \
##    && echo "@php http://php.codecasts.rocks/v3.8/php-7.2" >> /etc/apk/repositories \
##    && apk add --no-cache --update php7@php \
##    && apk add --no-cache --update php7-redis@php

RUN apk --no-cache add git \
    php7-redis \
    php7-pgsql \ 
    php7-sqlite3 \
    php7-gd \
    php7-xml \
    php7-xmlrpc \
    php7-curl

# Install lizmap web client
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

# Use the default production configuration
RUN mv $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini

COPY factory.manifest /build.manifest
COPY lizmapConfig.ini.php.dist localconfig.ini.php.dist /www/lizmap/var/config.dist/
COPY lizmap-entrypoint.sh update-config.php /bin/ 
RUN chmod 755 /bin/lizmap-entrypoint.sh /bin/update-config.php

WORKDIR /www
ENTRYPOINT ["/bin/lizmap-entrypoint.sh"]





