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
