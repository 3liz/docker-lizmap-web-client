#!/bin/sh

set -e
set -x

LIZMAP_USER=${LIZMAP_USER:-9001}

#function failenv () {
#    echo "Required variable $1 not defined"
#    exit 1
#}

# Check required configuration variables

# lizmapConfig.ini.php.dist

# Copy config files to mount point
cp -aR lizmap/var/config.dist/* lizmap/var/config
if [ ! -f lizmap/var/config/lizmapConfig.ini.php ]; then
    cp lizmap/var/config/lizmapConfig.ini.php.dist lizmap/var/config/lizmapConfig.ini.php
    cp lizmap/var/config/localconfig.ini.php.dist  lizmap/var/config/localconfig.ini.php
    cp lizmap/var/config/profiles.ini.php.dist     lizmap/var/config/profiles.ini.php
fi 

# Copy static files
# Note: static files needs to be resolved by external web server
# We have to copy them on the host
if [ -e lizmap/www ]; then
    cp -aR lizmap/www.dist/* lizmap/www/
    chown -R $LIZMAP_USER:$LIZMAP_USER lizmap/www
else
    mv lizmap/www.dist lizmap/www
fi

# Set configuration variables

sed -i '/^hideSensitiveServicesProperties=/c\hideSensitiveServicesProperties=1' lizmap/var/config/lizmapConfig.ini.php
sed -i '/^rootRepositories=/c\rootRepositories="/srv/projects"'                 lizmap/var/config/lizmapConfig.ini.php

sed -i "/^wmsServerURL=/c\wmsServerURL=${LIZMAP_WMSSERVERURL}"       lizmap/var/config/lizmapConfig.ini.php
sed -i "/^cacheRedisHost=/c\cacheRedisHost=${LIZMAP_CACHEREDISHOST}" lizmap/var/config/lizmapConfig.ini.php

[ ! -z "$LIZMAP_CACHEREDISPORT" ]      && sed -i "/^cacheRedisPort=/c\cacheRedisPort=${LIZMAP_CACHEREDISPORT}"       lizmap/var/config/lizmapConfig.ini.php
[ ! -z "$LIZMAP_CACHEEXPIRATION" ]     && sed -i "/^cacheExpiration=/c\cacheExpiration=${LIZMAP_CACHEEXPIRATION}"    lizmap/var/config/lizmapConfig.ini.php
[ ! -z "$LIZMAP_DEBUGMODE" ]           && sed -i "/^debugMode=/c\debugMode=${LIZMAP_DEBUGMODE}"                      lizmap/var/config/lizmapConfig.ini.php
[ ! -z "$LIZMAP_CACHESTORAGETYPE" ]    && sed -i "/^cacheStorageType=/c\cacheStorageType=${LIZMAP_CACHESTORAGETYPE}" lizmap/var/config/lizmapConfig.ini.php
[ ! -z "$LIZMAP_CACHEREDISDB" ]        && sed -i "/^cacheRedisDb=/c\cacheRedisDb=${LIZMAP_CACHEREDISDB}"             lizmap/var/config/lizmapConfig.ini.php
[ ! -z "$LIZMAP_CACHEREDISKEYPREFIX" ] && sed -i "/^cacheRedisKeyPrefix=/c\cacheRedisKeyPrefix=${LIZMAP_CACHEREDISKEYPREFIX}"  lizmap/var/config/lizmapConfig.ini.php

# Set up WPS configuration
sed -i "/^wps_rootUrl=/c\wps_rootUrl=${LIZMAP_WPS_URL}"      lizmap/var/config/localconfig.ini.php
sed -i "/^ows_url=/c\ows_url=${LIZMAP_WMSSERVERURL}" lizmap/var/config/localconfig.ini.php

# Redis WPS config
sed -i "/^redis_host=/c\redis_host=${LIZMAP_CACHEREDISHOST}" lizmap/var/config/localconfig.ini.php
# Optional config
[ ! -z "$LIZMAP_CACHEREDISPORT" ]  && sed -i "/^redis_port=/c\redis_port=${LIZMAP_CACHEREDISPORT}"   lizmap/var/config/localconfig.ini.php
[ ! -z "$LIZMAP_CACHEREDISDB" ]    && sed -i "/^redis_db=/c\redis_db=${LIZMAP_CACHEREDISDB}"         lizmap/var/config/localconfig.ini.php

# Set up Configuration  

php lizmap/install/installer.php

# Set owner/and group
sh lizmap/install/set_rights.sh $LIZMAP_USER $LIZMAP_USER

# No need to clean tmp
#sh lizmap/install/clean_vartmp.sh

# Create link to lizmap prefix
mkdir -p $(dirname $LIZMAP_HOME)
ln -sf /www/lizmap $LIZMAP_HOME

# Configure php-fpm
sed -i "/^user =/c\user = ${LIZMAP_USER}"   /usr/local/etc/php-fpm.d/www.conf
sed -i "/^group =/c\group = ${LIZMAP_USER}" /usr/local/etc/php-fpm.d/www.conf

exec docker-php-entrypoint $@

