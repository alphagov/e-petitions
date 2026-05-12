#!/usr/bin/env bash
set -e
set -o pipefail

su - deploy <<'EOF'
rm -rf /home/deploy/epetitions/current/.bundle
rm -f /home/deploy/epetitions/current/config/sso.yml
rm -f /home/deploy/epetitions/current/log
rm -f /home/deploy/epetitions/current/tmp
rm -f /home/deploy/epetitions/current/vendor/bundle
EOF
