FROM ruby:2.7

ARG VERSION=0.8.2

RUN gem install sqlite3 -v 1.6.9 && \
    gem install mailcatcher -v $VERSION

EXPOSE 1025 1080

ENTRYPOINT ["mailcatcher", "--foreground"]
CMD ["--ip", "0.0.0.0"]