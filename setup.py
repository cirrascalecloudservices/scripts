import setuptools
setuptools.setup(name='cirrascale-scripts', scripts=[
    'cirrascale-setup-bmcproxy.sh', 'cirrascale-render-bmcproxy-conf.py',
    'certbot-dns-lightsail-auth.py', 'certbot-dns-lightsail-clean.py',
    'setup-certbot.sh', 'setup-ssl-proxy.sh', 'setup-ssl-sso-proxy.sh'], requires=['pynetbox'])
