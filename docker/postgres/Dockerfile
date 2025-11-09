FROM postgres:16-bookworm

RUN apt-get update \
      && apt-cache showpkg postgresql-$PG_MAJOR-pgvector \
      && apt-get install -y --no-install-recommends \
           postgresql-$PG_MAJOR-pgvector \
      && rm -rf /var/lib/apt/lists/*
