FROM ruby:2.6

ENV BUNDLE_PATH=/bundle

# Install PostgreSQL client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' \
    > /etc/apt/sources.list.d/pgdg.list && \
    wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | apt-key add - && apt-get update && \
    apt-get install -y postgresql-client-10

# Install NodeJS
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs

# Install Bundler
RUN gem install bundler -v 1.17.3

# Install Chromium and Chromium-Driver
RUN apt-get install -y chromium chromium-driver

# Link chromedriver so the webdrivers gem finds it
RUN mkdir -p /root/.webdrivers && \
   ln -nfs /usr/bin/chromedriver /root/.webdrivers/chromedriver && \
   /usr/bin/chromedriver --version | cut -d ' ' -f 2 | cat > /root/.webdrivers/chromedriver.version

WORKDIR /app

CMD ["/bin/bash"]
