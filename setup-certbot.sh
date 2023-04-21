#!/bin/bash -ex

# Usage: $0 -d 'baz.example.com' -d '*.baz.example.com'

# cirrascale-opinionated certbot+lightsail helper
# [1] requires aws lightsail domain entry create/delete iam permissions

apt-get install certbot python3-boto3 -y

# auth
install <(cat << 'EOF'
#!/usr/bin/env python3

import boto3
import os
import time

CERTBOT_DOMAIN=os.environ['CERTBOT_DOMAIN']
print(CERTBOT_DOMAIN)
CERTBOT_VALIDATION=os.environ['CERTBOT_VALIDATION']
print(CERTBOT_VALIDATION)

client = boto3.client('lightsail', region_name='us-east-1')
domainName='.'.join(CERTBOT_DOMAIN.split('.')[-2:]) # e.g., cirrascale.net
domainEntry={
  'name':'_acme-challenge.{}'.format(CERTBOT_DOMAIN),
  'target':'"{}"'.format(CERTBOT_VALIDATION),
  'type':'TXT',
}
response = client.create_domain_entry(domainName=domainName, domainEntry=domainEntry)
print(response)

# Sleep to make sure the change has time to propagate over to DNS
time.sleep(25)
EOF
) /usr/local/bin/auth-certbot-dns-lightsail.py

# clean
install <(cat << 'EOF'
#!/usr/bin/env python3

import boto3
import os
import time

CERTBOT_DOMAIN=os.environ['CERTBOT_DOMAIN']
print(CERTBOT_DOMAIN)
CERTBOT_VALIDATION=os.environ['CERTBOT_VALIDATION']
print(CERTBOT_VALIDATION)

client = boto3.client('lightsail', region_name='us-east-1')
domainName='.'.join(CERTBOT_DOMAIN.split('.')[-2:]) # e.g., cirrascale.net
domainEntry={
  'name':'_acme-challenge.{}'.format(CERTBOT_DOMAIN),
  'target':'"{}"'.format(CERTBOT_VALIDATION),
  'type':'TXT',
}
response = client.delete_domain_entry(domainName=domainName, domainEntry=domainEntry)
print(response)
EOF
) /usr/local/bin/clean-certbot-dns-lightsail.py

# cron daily reload
install <(cat << 'EOF'
#!/bin/sh -e
systemctl reload apache2
EOF
) /etc/cron.daily/reload-apache

certbot certonly \
--agree-tos \
--register-unsafely-without-email \
--preferred-challenges dns \
--manual \
--manual-public-ip-logging-ok \
--manual-auth-hook auth-certbot-dns-lightsail.py \
--manual-cleanup-hook clean-certbot-dns-lightsail.py \
$*

# {{now}}
