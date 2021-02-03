# syntax =  docker/dockerfile:experimental
ARG ALPINE_VERSION

FROM --platform=${TARGETPLATFORM} alpine:${ALPINE_VERSION}
LABEL maintainer="Jorn Eilander <jorn.eilander@azorion.com>"
LABEL Description="Jackett"

# Define version of Jackett
ARG JACKETT_VERSION
ARG UID=9117
ARG GID=9117

# Install required base packages and remove any cache
RUN apk add --no-cache \
      tini \
      ca-certificates && \
    apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
      mono \
      gosu \
      curl && \
    apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
      mediainfo \
      tinyxml2 && \
    rm -rf /var/tmp/* /var/cache/apk/* && \
    # Fix mono-bug: https://gitlab.alpinelinux.org/alpine/aports/-/issues/12388
    ln -s /usr/lib/libmono-native.so.0 /usr/lib/libmono-native.so && \
    cert-sync /etc/ssl/certs/ca-certificates.crt && \
    # Create the 'jackett' user and ensure it's part of group 'root'; ensure it owns '/config'
    addgroup -g ${GID} jackett && \
    adduser -D -G jackett -s /bin/sh -u ${UID} jackett && \
    mkdir /config; chown -R ${UID}:${GID} /config && \
    mkdir /media/downloads; chown -R ${UID}:${GID} /media/downloads && \
    mkdir -p /tmp/.mono; chown -R ${UID}:${GID} /tmp/.mono

ADD --chown=${UID}:${GID} Jackett.Binaries.Mono.tar.gz /opt

# Fix a weird bug
RUN cp /usr/lib/mono/4.5/Facades/System.Runtime.InteropServices.RuntimeInformation.dll /opt/Jackett/

# Publish volumes, ports etc
ENV XDG_CONFIG_HOME=/tmp
ENV XDG_CONFIG_DIR=/tmp
VOLUME ["/config", "/media/downloads"]
EXPOSE 9117
USER 9117
WORKDIR /config

# Define default start command
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["mono", "/opt/Jackett/JackettConsole.exe", "-d", "/config", "-l"]


