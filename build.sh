#!/usr/bin/env bash

docker build --no-cache \
  -t "rubensa/ubuntu-tini-dev-chrome" \
  --label "maintainer=Ruben Suarez <rubensa@gmail.com>" \
  .
