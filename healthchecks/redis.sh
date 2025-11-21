#!/bin/sh
set -eo pipefail

host="$(hostname -i || echo '127.0.0.1')"

# Check if Redis password is set
if [ -n "$REDIS_PASSWORD" ]; then
    ping="$(redis-cli -h "$host" -a "$REDIS_PASSWORD" --no-auth-warning ping 2>/dev/null)"
else
    ping="$(redis-cli -h "$host" ping)"
fi

if [ "$ping" = 'PONG' ]; then
    exit 0
fi

exit 1
