FROM debian:stable-slim

# Run security updates and install packages
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update -qq && \
    apt-get install -y dnsmasq && \
    apt-get upgrade -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 53 53/udp

ENTRYPOINT ["dnsmasq", "-k"]
