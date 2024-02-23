#!/usr/bin/env bash
set -e
set -o pipefail

chown -R deploy:deploy /home/deploy/epetitions/releases/<%= release %>

su - deploy <<'EOF'
ln -nfs /home/deploy/epetitions/shared/tmp /home/deploy/epetitions/releases/<%= release %>/tmp
ln -nfs /home/deploy/epetitions/shared/log /home/deploy/epetitions/releases/<%= release %>/log
ln -nfs /home/deploy/epetitions/shared/bundle /home/deploy/epetitions/releases/<%= release %>/vendor/bundle
ln -nfs /home/deploy/epetitions/shared/assets /home/deploy/epetitions/releases/<%= release %>/public/assets
ln -s /home/deploy/epetitions/releases/<%= release %> /home/deploy/epetitions/current_<%= release %>
mv -Tf /home/deploy/epetitions/current_<%= release %> /home/deploy/epetitions/current
cd /home/deploy/epetitions/current && bundle config set --local deployment 'true'
cd /home/deploy/epetitions/current && bundle config set --local without 'development test'
cd /home/deploy/epetitions/current && bundle install --quiet
cd /home/deploy/epetitions/current && bundle exec rake db:migrate
cd /home/deploy/epetitions/current && bundle exec rake assets:precompile
if [ ${SERVER_TYPE} = "worker" ] ; then cd /home/deploy/epetitions/current && bundle exec whenever -w ; else echo not running whenever ; fi
EOF

# Enable services if they have not been previously enabled
if [ -f "/etc/init.d/epetitions" ]; then
  /lib/systemd/systemd-sysv-install is-enabled epetitions || /lib/systemd/systemd-sysv-install enable epetitions
else
  systemctl is-active --quiet epetitions.service || systemctl enable epetitions.service
fi
