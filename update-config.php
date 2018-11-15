#!/usr/bin/env php
<?php

function update_ini_file($filename, $update) {

    $config = $update(parse_ini_file($filename, true));
    $body  = ";<?php die(''); ?>\n;for security reasons , don't remove or modify the first line\n";
    $body .= ";LAST UPDATED: ".date(DATE_RFC2822)."\n\n";

    // write global variable
    foreach ($config as $section => $content) {
        if(!is_array($content)) {
            $body .= "$section=$content\n";
        }
    }

    foreach ($config as $section => $content) {
        if(!is_array($content)) continue;
        $content = array_map(function($val,$key) {
            return "$key=$val";
        },array_values($content),array_keys($content));
        $content = implode("\n", $content); // concat
        $body .= "\n[$section]\n$content\n";
    }
    file_put_contents($filename, $body);    
}

// Update localconfig 
update_ini_file( 'lizmap/var/config/localconfig.ini.php', function($config) {

// Set up WPS configuration
if ( getenv("LIZMAP_WPS_URL") ) {
    $config['modules']['wps.access'] = '2';
    $config['wps']['wps_rootUrl'] = getenv('LIZMAP_WPS_URL');
    $config['wps']['ows_url']     = getenv('LIZMAP_WMSSERVERURL');
    $config['wps']['wps_rootDirectories'] = "/srv/projects";
    // Redis config
    $config['wps']['redis_port'] = getenv('LIZMAP_CACHEREDISPORT') ?: 6379;
    $config['wps']['redis_host'] = getenv('LIZMAP_CACHEREDISHOST') ?: 'redis';
    $config['wps']['redis_db']   = getenv('LIZMAP_CACHEREDISDB')   ?: 1;
    $config['wps']['redis_key_prefix'] = "wpslizmap";
} else {
    $config['modules']['wps.access'] = '0';
}

// Set urlengine config
unset($config['urlengine']);
unset($config['forceHTTPSPort']);

if(getenv('LIZMAP_PROXYURL_PROTOCOL')) {
    $config['urlengine']['checkHttpsOnParsing'] = 'off';
    $config['urlengine']['forceProxyProtocol']  = getenv('LIZMAP_PROXYURL_PROTOCOL');
    // By default, use the 443 https port  
    if(getenv('LIZMAP_PROXYURL_HTTPS_PORT')) $config['forceHTTPSPort'] = getenv('LIZMAP_PROXYURL_HTTPS_PORT');
    else $config['forceHTTPSPort'] = '443';
}

if(getenv('LIZMAP_PROXYURL_DOMAIN'))          $config['urlengine']['domainName']      = getenv('LIZMAP_PROXYURL_DOMAIN');
if(getenv('LIZMAP_PROXYURL_BASEPATH'))        $config['urlengine']['basePath']        = getenv('LIZMAP_PROXYURL_BASEPATH');
if(getenv('LIZMAP_PROXYURL_BACKENDBASEPATH')) $config['urlengine']['backendBasePath'] = getenv('LIZMAP_PROXYURL_BACKENDBASEPATH');

return $config;

})



?>
