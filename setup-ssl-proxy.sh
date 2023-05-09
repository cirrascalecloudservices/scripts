#!/bin/sh -ex

# STEP 0 iff ubuntu 20.04 or older
# sudo add-apt-repository ppa:ondrej/apache2

# STEP 1
# sudo apt install apache2

# STEP 2
# sudo a2enmod proxy_http ssl

# STEP 3
# sudo systemctl restart apache2

# Example: setup-ssl-proxy.sh maas san01 http://localhost:5240

HOST=${1?}
SITE=${2?}
TO=${3?}

cat > /etc/apache2/sites-available/${HOST?}.${SITE?}.cirrascale.net.conf << EOF
#Listen 80
<VirtualHost *:80>
 ServerName ${HOST?}.${SITE?}.cirrascale.net
 #ServerAlias *.${HOST?}.${SITE?}.cirrascale.net
 Redirect / https://${HOST?}.${SITE?}.cirrascale.net/
</VirtualHost>
#Listen 443
<VirtualHost *:443>
 ServerName ${HOST?}.${SITE?}.cirrascale.net
 #ServerAlias *.${HOST?}.${SITE?}.cirrascale.net
 # ssl
 SSLEngine on
 SSLCertificateFile /etc/letsencrypt/live/${HOST?}.${SITE?}.cirrascale.net/fullchain.pem
 SSLCertificateKeyFile /etc/letsencrypt/live/${HOST?}.${SITE?}.cirrascale.net/privkey.pem
 # proxy
 <Location />
  ProxyPass ${TO?}/ upgrade=websocket
 </Location>
</VirtualHost>
EOF

a2ensite ${HOST?}.${SITE?}.cirrascale.net.conf

systemctl reload apache2

# {{now}}
