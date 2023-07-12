#!/bin/bash
set -euxo pipefail
shopt -s inherit_errexit
# https://dougrichardson.us/notes/fail-fast-bash-scripting.html

site=$1

# add-apt-repository ppa:ondrej/apache2 -y # iff ubuntu 20.04
apt-get install apache2 libapache2-mod-auth-openidc -y
a2enmod auth_openidc proxy_http ssl
a2ensite default-ssl
cirrascale-render-bmcproxy-conf.py $site > /etc/apache2/sites-available/cirrascale-bmcproxy.conf
a2ensite cirrascale-bmcproxy

install <(cat << EOF
#!/bin/bash
set -euxo pipefail
shopt -s inherit_errexit
# https://dougrichardson.us/notes/fail-fast-bash-scripting.html

# STEP 1 render
cirrascale-render-bmcproxy-conf.py $site > /etc/apache2/sites-available/cirrascale-bmcproxy.conf
# STEP 2 reload
systemctl reload apache2
EOF
) /etc/cron.daily/cirrascale-bmcproxy

# restart
systemctl restart apache2

# {now}
