#!/usr/bin/env bash
set -e
set -o pipefail

su - deploy <<'EOF'
rm -rf /home/deploy/epetitions/current/.bundle
rm -f /home/deploy/epetitions/current/log
rm -f /home/deploy/epetitions/current/tmp
rm -f /home/deploy/epetitions/current/vendor/bundle
rm -f /home/deploy/epetitions/current/public/assets
rm -f /home/deploy/epetitions/current/public/400.html
rm -f /home/deploy/epetitions/current/public/403.html
rm -f /home/deploy/epetitions/current/public/404.html
rm -f /home/deploy/epetitions/current/public/406.html
rm -f /home/deploy/epetitions/current/public/422.html
rm -f /home/deploy/epetitions/current/public/500.html
rm -f /home/deploy/epetitions/current/public/503.html
rm -f /home/deploy/epetitions/current/public/error.css
EOF
