#!/bin/bash

PASSWORD="andreas1234"
REMOTE_USER="morten"
REMOTE_HOST="morten.local"
REMOTE_DIR="~/adc_sampler/"
PATTERN="out*"

sshpass -p "$PASSWORD" scp "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR$PATTERN" ./data/
