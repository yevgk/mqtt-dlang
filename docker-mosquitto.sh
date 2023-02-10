#!/usr/bin/env bash

# Absolute path to this script
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in
BASEDIR=$(dirname "$SCRIPT")


mkdir -p ${BASEDIR}/mosquitto/log
mkdir -p ${BASEDIR}mosquitto/data

docker stop mosquitto && docker rm mosquitto
docker run -d \
  --name mosquitto \
  --restart=unless-stopped \
  -p 1883:1883 -p 9001:9001 \
  -v ${BASEDIR}/mosquitto/config/mosquitto.conf:/mosquitto/config/mosquitto.conf \
  -v ${BASEDIR}/mosquitto/data:/mosquitto/data \
  -v ${BASEDIR}/mosquitto/log:/mosquitto/log \
  eclipse-mosquitto

