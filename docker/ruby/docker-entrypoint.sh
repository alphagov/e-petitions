#!/bin/bash

set -e

echo 'Waiting for a connection with postgres...'

until psql $DATABASE_URL -c '\q' > /dev/null 2>&1; do
  sleep 1
done

echo 'Connected to postgres...'

if [ "$1" = "bash" ]; then
  exec "$@"
else
  npm install --no-fund --no-audit
  bundle check || bundle install

  exec bundle exec "$@"
fi
