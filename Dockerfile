# syntax =  docker/dockerfile:experimental

ARG ALPINE_VERSION

FROM --platform=${TARGETPLATFORM} alpine:${ALPINE_VERSION} AS BUILD

ARG DOTNET_SDK_FILE
ARG JACKETT_VERSION

RUN apk add icu-libs krb5-libs libgcc libintl libssl1.1 libstdc++ zlib curl lttng-ust numactl zlib git && \
    mkdir -p /opt/dotnet

ADD ${DOTNET_SDK_FILE} /opt/dotnet
ENV PATH=${PATH}:/opt/dotnet

RUN git clone --depth 1 --branch ${JACKETT_VERSION} https://github.com/Jackett/Jackett.git

WORKDIR /Jackett/src

RUN dotnet publish "Jackett.Server" \
    --configuration Release \
    --runtime linux-musl-x64 \
    --framework net5.0 \
    /p:AssemblyVersion="${JACKETT_VERSION:1}" /p:FileVersion="${JACKETT_VERSION:1}" /p:InformationalVersion="${JACKETT_VERSION:1}" /p:Version="${JACKETT_VERSION:1}"

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
      icu-libs \
      krb5-libs \
      libgcc \
      libintl \
      libssl1.1 \
      libstdc++ \
      lttng-ust \
      numactl \
      zlib &&\
    rm -rf /var/tmp/* /var/cache/apk/* && \
    # Create the 'jackett' user and ensure it owns '/config'
    addgroup -g ${GID} jackett && \
    adduser -D -G jackett -s /bin/sh -u ${UID} jackett && \
    mkdir /config; chown -R ${UID}:${GID} /config && \
    mkdir /media/downloads; chown -R ${UID}:${GID} /media/downloads

COPY --from=BUILD /Jackett/src/Jackett.Server/bin/Release/net5.0/linux-musl-x64 /opt/jackett

# Publish volumes, ports etc
ENV XDG_CONFIG_HOME="/config/xdg"
VOLUME ["/config", "/media/downloads"]
EXPOSE 9117
USER ${UID}
WORKDIR /config

# Define default start command
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/opt/jackett/jackett", "--DataFolder=/config", "--Logging", "--NoUpdates"]
