FROM ruby:3.0

ENV BUNDLE_PATH=/bundle

# Install PostgreSQL client
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main' \
    > /etc/apt/sources.list.d/pgdg.list && \
    wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    | apt-key add - && apt-get update && \
    apt-get install -y postgresql-client-10

# Install required GIS packages
RUN apt-get install -y libgeos-dev libproj-dev gdal-bin

# Install NodeJS
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "14.21.3" /usr/local/node && \
    rm -rf /tmp/node-build-master

# Install Bundler
RUN gem install bundler -v 2.3.26

# Install Chromium and Chromium-Driver
RUN apt-get install -y chromium chromium-driver

# Link chromedriver so the webdrivers gem finds it
RUN mkdir -p /root/.webdrivers && \
   ln -nfs /usr/bin/chromedriver /root/.webdrivers/chromedriver && \
   /usr/bin/chromedriver --version | cut -d ' ' -f 2 | cat > /root/.webdrivers/chromedriver.version

# Create the crash reports directory - without it Chromium complains on startup
RUN mkdir -p "/root/.config/chromium/Crash Reports/pending/"

WORKDIR /app

COPY ./docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/bin/bash"]
