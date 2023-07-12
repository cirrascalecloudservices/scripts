import setuptools
setuptools.setup(name='cirrascale-scripts', scripts=[
    'cirrascale-secure-conf.py', 'cirrascale-bmc-secure-conf.py',
    'certbot-dns-lightsail-auth.py', 'certbot-dns-lightsail-clean.py',
    'setup-certbot.sh', 'setup-ssl-proxy.sh', 'setup-ssl-sso-proxy.sh'])
