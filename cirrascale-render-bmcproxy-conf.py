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
site=netbox.dcim.sites.get(slug=os.environ['NETBOX_SITE'])
domainname='secure.{}.cirrascale.net'.format(site.slug)

print(f"""\
# /etc/apache2/sites-available/cirrascale-bmcproxy.conf

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

def domainify(s: str):
    return '-'.join(re.split('[^a-zA-Z0-9]+', s)).lower().strip('-')

def partition(list: list, n: int):
    return [list[i:i + n] for i in range(0, len(list), n)]

interface_ids = []
for interface in netbox.dcim.interfaces.filter(site=site.slug, mgmt_only='true', brief=1):
    interface_ids.append(interface.id)

for interface_ids in partition(interface_ids, 50):
    for ipaddress in netbox.ipam.ip_addresses.filter(interface_id=interface_ids):
        servername='.'.join([f'bmc-{ipaddress.assigned_object.device.id}', domainname])
        serveralias='.'.join([f'{domainify(ipaddress.assigned_object.device.name)}-bmc', domainname])
        to=ipaddress.address.split('/')[0]
        print(f"""\
# {ipaddress.assigned_object.device.name} {ipaddress.assigned_object.name}
#Listen 80
<VirtualHost *:80>
 ServerName {servername}
 ServerAlias {serveralias}
 Redirect / https://{servername}/
</VirtualHost>
#Listen 443
<VirtualHost *:443>
 ServerName {servername}
 ServerAlias {serveralias}
 # ssl
 SSLEngine on
 SSLCertificateFile /etc/letsencrypt/live/{domainname}/fullchain.pem
 SSLCertificateKeyFile /etc/letsencrypt/live/{domainname}/privkey.pem
 # ssl proxy
 SSLProxyEngine on
 SSLProxyCheckPeerCN off
 SSLProxyCheckPeerName off
 SSLProxyCheckPeerExpire off
 # sso proxy
 <Location />
  AuthType openid-connect
  Require valid-user
  ProxyPass https://{to}/ upgrade=websocket
 </Location>
</VirtualHost>
""")
