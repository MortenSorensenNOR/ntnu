#!/bin/bash

PASSWORD="andreas1234"
REMOTE_USER="morten"
REMOTE_HOST="morten.local"
REMOTE_DIR="~/adc_sampler/"
PATTERN="*.bin"

echo "=== Fetching $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR$PATTERN ==="

# List remote files first so we know what's coming
echo "Remote files:"
sshpass -p "$PASSWORD" ssh "$REMOTE_USER@$REMOTE_HOST" "ls -lh ${REMOTE_DIR}${PATTERN} 2>/dev/null || echo '  (none found)'"

echo ""
echo "Transferring..."

sshpass -p "$PASSWORD" rsync -av --progress \
    --rsh="ssh" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR$PATTERN" \
    ./data/

echo ""
echo "Done. Local data/:"
ls -lh ./data/out* 2>/dev/null || echo "  (no out* files)"
