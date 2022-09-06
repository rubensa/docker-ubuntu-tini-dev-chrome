#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ubuntu-tini-dev-chrome"

docker stop  \
  "${DOCKER_IMAGE_NAME}"
