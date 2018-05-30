#!/usr/bin/env bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE epets_development;
    CREATE DATABASE epets_test;
    CREATE USER epets;
    GRANT all privileges ON database epets_development TO epets;
    GRANT all privileges ON database epets_test TO epets;
    ALTER USER epets WITH PASSWORD 'replace_me';
EOSQL

