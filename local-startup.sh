#!/usr/bin/env bash
set -e

which docker > /dev/null || (echo "docker not installed" && exit 1)

echo "Building database docker image..."
docker build -t epetition_dev_postgres docker/

# this will shutdown database whenever this script exits
function database_cleanup() {
    docker stop epetition_dev_postgres
}
trap database_cleanup EXIT

# a clean database is used each time this starts
echo "Starting database..."
docker run --name epetition_dev_postgres --rm -p 5432:5432 epetition_dev_postgres > database.log 2>&1 &

echo -n "Waiting for database to become ready..."
SECONDS_TO_WAIT=10
while [ $(grep "database system is ready to accept connections" database.log | wc -l) -lt 1 ]; do
    let SECONDS_TO_WAIT=$SECONDS_TO_WAIT-1
    sleep 1
    if [ $SECONDS_TO_WAIT -lt 1 ]; then
        echo "database was not ready in time"
        exit 1
    fi
    echo -n "."
done
echo " ready"

echo "Checking bundles..."
bundle check || bundle install
echo "Running migrations..."
bin/rake db:migrate RAILS_ENV=development
echo "Starting app..."
rails s
