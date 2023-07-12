#!/bin/bash
set -euxo pipefail
shopt -s inherit_errexit
# https://dougrichardson.us/notes/fail-fast-bash-scripting.html

# Usage: setup-certbot.sh
# Usage: setup-certbot.sh -d 'baz.example.com' -d '*.baz.example.com'

apt-get install certbot python3-boto3 -y

# cron daily reload apache
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
--manual-auth-hook certbot-dns-lightsail-auth.py \
--manual-cleanup-hook certbot-dns-lightsail-clean.py \
$*

# {{now}}
