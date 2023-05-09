#!/bin/bash -ex

# STEP 0 iff ubuntu 20.04 or older
# sudo add-apt-repository ppa:ondrej/apache2

# STEP 1
# sudo apt install apache2 libapache2-mod-auth-openidc

# STEP 2
# sudo a2enmod auth_openidc macro proxy_http ssl

# STEP 3
# sudo systemctl restart apache2

# Usage: setup-ssl-sso-proxy.sh hype9f8-pve san01 https://172.17.0.252:8006
  # -> https://hype9f8-pve.san01.proxy.cirrascale.net

HOST=${1?}
SITE=${2?} # <- /etc/cirrascale/site
TO=${3?}

cat > /etc/apache2/conf-available/${SITE?}.proxy.cirrascale.net.conf << EOF
# sso
OIDCClientID ${OIDCClientID?}
OIDCClientSecret ${OIDCClientSecret?}
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
