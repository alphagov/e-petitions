FROM ruby:2.2.4

RUN apt-get update; apt-get install -y sqlite3 libsqlite3-dev
RUN gem install mailcatcher --no-rdoc --no-ri

CMD mailcatcher -f --ip 0.0.0.0
