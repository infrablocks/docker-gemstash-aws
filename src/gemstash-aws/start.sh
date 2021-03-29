#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

config_file=\
"${GEMSTASH_CONFIG_FILE:-/opt/gemstash/conf/gemstash.yml}"

mkdir -p "$(dirname "${config_file}")"
echo "---" >> "${config_file}"

if [ -n "${GEMSTASH_STORAGE_ADAPTER}" ]; then
  echo ":storage_adapter: \"${GEMSTASH_STORAGE_ADAPTER}\"" >> "${config_file}"
else
  echo ":storage_adapter: \"local\"" >> "${config_file}"
fi

if [ -n "${GEMSTASH_BASE_PATH}" ]; then
  echo ":base_path: \"${GEMSTASH_BASE_PATH}\"" >> "${config_file}"
else
  echo ":base_path: \"/var/opt/gemstash\"" >> "${config_file}"
fi

if [ -n "${GEMSTASH_S3_PATH}" ]; then
  option=":s3_path: \"${GEMSTASH_S3_PATH}\""
  echo "${option}" >> "${config_file}"
fi

if [ -n "${GEMSTASH_AWS_ACCESS_KEY}" ]; then
  option=":aws_access_key: \"${GEMSTASH_AWS_ACCESS_KEY}\""
  echo "${option}" >> "${config_file}"
fi

if [ -n "${GEMSTASH_AWS_SECRET_ACCESS_KEY}" ]; then
  option=":aws_secret_access_key: \"${GEMSTASH_AWS_SECRET_ACCESS_KEY}\""
  echo "${option}" >> "${config_file}"
fi

if [ -n "${GEMSTASH_BUCKET_NAME}" ]; then
  option=":bucket_name: \"${GEMSTASH_BUCKET_NAME}\""
  echo "${option}" >> "${config_file}"
fi

if [ -n "${GEMSTASH_REGION}" ]; then
  option=":region: \"${GEMSTASH_REGION}\""
  echo "${option}" >> "${config_file}"
fi

if [ -n "${GEMSTASH_CACHE_TYPE}" ]; then
  echo ":cache_type: \"${GEMSTASH_CACHE_TYPE}\"" >> "${config_file}"
else
  echo ":cache_type: \"memory\"" >> "${config_file}"
fi

if [ -n "${GEMSTASH_CACHE_MAX_SIZE}" ]; then
  echo ":cache_max_size: ${GEMSTASH_CACHE_MAX_SIZE}" >> "${config_file}"
else
  echo ":cache_max_size: 500" >> "${config_file}"
fi

if [ -n "${GEMSTASH_CACHE_EXPIRATION}" ]; then
  echo ":cache_expiration: ${GEMSTASH_CACHE_EXPIRATION}" >> "${config_file}"
else
  echo ":cache_expiration: 1800" >> "${config_file}"
fi

if [ -n "${GEMSTASH_MEMCACHED_SERVERS}" ]; then
  option=":memcached_servers: \"${GEMSTASH_MEMCACHED_SERVERS}\""
  echo "${option}" >> "${config_file}"
fi

if [ -n "${GEMSTASH_BIND}" ]; then
  echo ":bind: \"${GEMSTASH_BIND}\"" >> "${config_file}"
else
  echo ":bind: \"tcp://0.0.0.0:9292\"" >> "${config_file}"
fi

if [ -n "${GEMSTASH_PUMA_THREADS}" ]; then
  option=":puma_threads: ${GEMSTASH_PUMA_THREADS}"
  echo "${option}" >> "${config_file}"
fi

if [ -n "${GEMSTASH_PUMA_WORKERS}" ]; then
  option=":puma_workers: ${GEMSTASH_PUMA_WORKERS}"
  echo "${option}" >> "${config_file}"
fi

if [ -n "${GEMSTASH_FETCH_TIMEOUT}" ]; then
  echo ":fetch_timeout: ${GEMSTASH_FETCH_TIMEOUT}" >> "${config_file}"
else
  echo ":fetch_timeout: 20" >> "${config_file}"
fi

if [[ "$GEMSTASH_PROTECTED_FETCH_ENABLED" = "yes" ]]; then
  echo ":protected_fetch: true" >> "${config_file}"
fi

if [ -n "${GEMSTASH_DB_ADAPTER}" ]; then
  option=":db_adapter: \"${GEMSTASH_DB_ADAPTER}\""
  echo "${option}" >> "${config_file}"
fi

if [ -n "${GEMSTASH_DB_URL}" ]; then
  option=":db_url: \"${GEMSTASH_DB_URL}\""
  echo "${option}" >> "${config_file}"
fi

if [ -n "${GEMSTASH_DB_CONNECTION_OPTIONS}" ]; then
  option=":db_connection_options: ${GEMSTASH_DB_CONNECTION_OPTIONS}"
  echo "${option}" >> "${config_file}"
fi

cat "${config_file}"

echo "Running gemstash."
exec su-exec gemstash:gemstash /usr/bin/gemstash start \
    --no-daemonize \
    --config-file="${config_file}" \
    "$@"
