#!/bin/bash

PASSWORD="mortenerkul67"
REMOTE_USER="morten"
REMOTE_HOST="morten.local"
REMOTE_DIR="~/adc_sampler/"
PATTERN="out*"

mkdir -p ./data
sshpass -p "$PASSWORD" scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR$PATTERN" ./data/
