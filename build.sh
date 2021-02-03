#!/bin/bash
set -e

ALPINE_VERSION=3.12
IMAGE_NAME=failfr8er/jackett
JACKETT_RAW=$(curl -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/jackett/jackett/releases/latest)
JACKETT_VERSION=$(echo "${JACKETT_RAW}" | jq -r '.tag_name')
JACKETT_ASSET=$(echo "${JACKETT_RAW}" | jq -r '.assets[] | select(.name == "Jackett.Binaries.Mono.tar.gz").browser_download_url')

wget "${JACKETT_ASSET}"

docker buildx build \
  --file Dockerfile \
  --cache-from=type=local,src=/tmp/.buildx \
  --cache-to=type=local,dest=/tmp/.buildx \
  --tag ${IMAGE_NAME}:${JACKETT_VERSION} \
  --tag ${IMAGE_NAME}:latest \
  --push \
  --build-arg ALPINE_VERSION=${ALPINE_VERSION} \
  --build-arg JACKETT_VERSION=${JACKETT_VERSION} \
  --platform=linux/amd64 \
  .

rm "Jackett.Binaries.Mono.tar.gz"