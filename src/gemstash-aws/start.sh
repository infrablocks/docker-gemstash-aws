#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

config_file=\
"${GEMSTASH_CONFIG_FILE:-/opt/gemstash/conf/gemstash.yml}"

mkdir -p "$(dirname "${config_file}")"
echo "---" >> "${config_file}"

echo "Running gemstash."
exec su-exec gemstash:gemstash /usr/bin/gemstash start \
    --no-daemonize \
    --config-file="${config_file}" \
    "$@"
