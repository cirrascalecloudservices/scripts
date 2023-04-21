#!/bin/bash -ex

# USAGE: setup-sso-proxy.sh hype9f8-pve san01 https://172.17.0.252:8006
  # -> https://hype9f8-pve.san01.proxy.cirrascale.net

# bmc-440.san01.proxy.cirrascale.net
# setup-certbot.sh -d 'san01.proxy.cirrascale.net' -d '*.san01.proxy.cirrascale.net'

HOST=${1?}
SITE=${2?}
TO=${3?}

cat > /etc/apache2/conf-available/${SITE?}.proxy.cirrascale.net.conf << EOF
# sso
OIDCClientID $(cat /etc/cirrascale/OIDCClientID)
OIDCClientSecret $(cat /etc/cirrascale/OIDCClientSecret)
OIDCProviderMetadataURL https://sso.cirrascale.com/realms/cirrascale-staff/.well-known/openid-configuration
OIDCRedirectURI https://${SITE?}.proxy.cirrascale.net/redirect_uri
OIDCCookieDomain ${SITE?}.proxy.cirrascale.net
OIDCCryptoPassphrase $(uuidgen)
# default http response
<VirtualHost *:80>
 ServerName ${SITE?}.proxy.cirrascale.net
 Redirect 404 /
</VirtualHost>
# default https response
<VirtualHost *:443>
 ServerName ${SITE?}.proxy.cirrascale.net
 SSLEngine on
 SSLCertificateFile /etc/letsencrypt/live/${SITE?}.proxy.cirrascale.net/fullchain.pem
 SSLCertificateKeyFile /etc/letsencrypt/live/${SITE?}.proxy.cirrascale.net/privkey.pem
 <Location />
  AuthType openid-connect
  Require valid-user
  Redirect 404 /
 </Location>
</VirtualHost>
EOF

cat > /etc/apache2/sites-available/${HOST?}.${SITE?}.proxy.cirrascale.net.conf << EOF
<VirtualHost *:80>
 ServerName ${HOST?}.${SITE?}.proxy.cirrascale.net
 Redirect / https://${HOST?}.${SITE?}.proxy.cirrascale.net/
</VirtualHost>
<VirtualHost *:443>
 ServerName ${HOST?}.${SITE?}.proxy.cirrascale.net
 # ssl
 SSLEngine on
 SSLCertificateFile /etc/letsencrypt/live/${SITE?}.proxy.cirrascale.net/fullchain.pem
 SSLCertificateKeyFile /etc/letsencrypt/live/${SITE?}.proxy.cirrascale.net/privkey.pem
 # ssl proxy
 SSLProxyEngine on
 SSLProxyCheckPeerCN off
 SSLProxyCheckPeerName off
 SSLProxyCheckPeerExpire off
 # sso proxy
 <Location />
  AuthType openid-connect
  Require valid-user
  ProxyPass ${TO?}/ upgrade=websocket
 </Location>
</VirtualHost>
EOF

a2enconf ${SITE?}.proxy.cirrascale.net.conf
a2ensite ${HOST?}.${SITE?}.proxy.cirrascale.net.conf
