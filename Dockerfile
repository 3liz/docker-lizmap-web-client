ARG REGISTRY_PREFIX=''
FROM ${REGISTRY_PREFIX}php:7.2-fpm-alpine3.7
MAINTAINER David Marteau <david.marteau@3liz.com>
LABEL Description="Lizmap web client" Vendor="3liz.org" Version="3.2"

ARG lizmap_version=master
ARG lizmap_archive=https://github.com/3liz/lizmap-web-client/archive/${lizmap_version}.zip

ARG lizmap_wps_version=master
ARG lizmap_wps_archive=https://github.com/3liz/lizmap-wps-web-client-module/archive/${lizmap_wps_version}.zip 

# trust this project public key to trust the packages.
ADD https://php.codecasts.rocks/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

RUN apk --no-cache add curl unzip \
    && echo "@php http://php.codecasts.rocks/v3.6/php-7.2" >> /etc/apk/repositories \
    && apk add --no-cache --update php7@php \
    && apk add --no-cache --update php7-redis@php

# Install lizmap
RUN echo $lizmap_archive \
   && curl -Ls -X GET  $lizmap_archive --output lizmap-web-client.zip \
   && unzip -q lizmap-web-client.zip \
   && rm lizmap-web-client.zip \
   && rm -rf lizmap-web-client-${lizmap_version}/vagrant \
   && mv lizmap-web-client-${lizmap_version} /www \
   && mv /www/lizmap/var/config /www/lizmap/var/config.dist \
   && mv /www/lizmap/www /www/lizmap/www.dist

# Install lizmap wps
RUN echo $lizmap_wps_version \
  && curl -Ls -X GET  $lizmap_wps_archive --output lizmap-wps-web-client.zip \
  && unzip -q lizmap-wps-web-client.zip \
  && rm lizmap-wps-web-client.zip \
  && mv lizmap-wps-web-client-module-${lizmap_wps_version}/wps /www/lizmap/lizmap-modules/wps \
  && rm -rf lizmap-wps-web-client-module-${lizmap_wps_version}

COPY factory.manifest /build.manifest
COPY lizmapConfig.ini.php.dist localconfig.ini.php.dist /www/lizmap/var/config.dist/
COPY lizmap-entrypoint.sh /bin/ 
RUN chmod 755 /bin/lizmap-entrypoint.sh

WORKDIR /www
ENTRYPOINT ["/bin/lizmap-entrypoint.sh"]





