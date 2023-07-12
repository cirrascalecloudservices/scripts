#!/usr/bin/env python3

import os
import re
import sys
import uuid
import pynetbox

# add-apt-repository ppa:ondrej/apache2 -y # iff ubuntu 20.04
# apt-get install apache2 libapache2-mod-auth-openidc -y
# a2enmod auth_openidc proxy_http ssl
# a2ensite default-ssl
# systemctl restart apache2

url=os.environ['NETBOX_URL']
apikey=os.environ['NETBOX_APIKEY']
netbox=pynetbox.api(url, apikey)
site=netbox.dcim.sites.get(slug=sys.argv[1])
domainname='secure.{}.cirrascale.net'.format(site.slug)

print(f"""\
# /etc/apache2/sites-available/cirrascale-secure.conf

# sso
OIDCProviderMetadataURL https://sso.cirrascale.com/realms/cirrascale-staff/.well-known/openid-configuration
OIDCClientID {site.custom_fields['OIDCClientID']}
OIDCClientSecret {site.custom_fields['OIDCClientSecret']}
OIDCRedirectURI https://{domainname}/redirect_uri
OIDCCookieDomain {domainname}
OIDCCryptoPassphrase {uuid.uuid4()}

# default http response
<VirtualHost *:80>
 ServerName {domainname}
 Redirect 404 /
</VirtualHost>

# default https response
<VirtualHost *:443>
 ServerName {domainname}
 SSLEngine on
 SSLCertificateFile /etc/letsencrypt/live/{domainname}/fullchain.pem
 SSLCertificateKeyFile /etc/letsencrypt/live/{domainname}/privkey.pem
 <Location />
  AuthType openid-connect
  Require valid-user
  Redirect 404 /
 </Location>
</VirtualHost>
""")
