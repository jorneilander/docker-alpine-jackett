#!/bin/bash
set -e

ALPINE_VERSION=3.12
IMAGE_NAME=failfr8er/jackett
JACKETT_RAW=$(curl -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/jackett/jackett/releases/latest)
JACKETT_VERSION=$(echo "${JACKETT_RAW}" | jq -r '.tag_name')

DOTNET_SDK_RAW=$(curl -H "Accept: application/vnd.github.v3+json" -s https://api.github.com/repos/dotnet/sdk/releases/latest)
DOTNET_SDK_VERSION=$(echo "${DOTNET_SDK_RAW}" | jq -r '.tag_name')
DOTNET_SDK_FILE="dotnet-sdk-5.0.102-linux-musl-x64.tar.gz"

[ ! -f "${DOTNET_SDK_FILE}" ] && wget "https://download.visualstudio.microsoft.com/download/pr/bf715f3d-ab8a-42a1-83ce-f6e1524a9f58/8d970618369fe8e6917a49c05aac58db/${DOTNET_SDK_FILE}"

docker buildx build \
  --file Dockerfile \
  --cache-from=type=local,src=/tmp/.buildx-cache \
  --cache-to=type=local,dest=/tmp/.buildx-cache \
  --tag "${IMAGE_NAME}":"${JACKETT_VERSION}" \
  --tag "${IMAGE_NAME}":latest \
  --push \
  --build-arg ALPINE_VERSION="${ALPINE_VERSION}" \
  --build-arg JACKETT_VERSION="${JACKETT_VERSION}" \
  --build-arg DOTNET_SDK_FILE="${DOTNET_SDK_FILE}" \
  --platform=linux/amd64 \
  .
