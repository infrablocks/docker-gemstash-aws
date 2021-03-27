#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

echo "Running gemstash."
# shellcheck disable=SC2086
exec /opt/gemstash/bin/gemstash \
    "$@"
