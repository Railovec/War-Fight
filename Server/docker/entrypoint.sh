#!/bin/sh
set -e
GODOT_PORT="${GODOT_PORT:-8081}"
LISTEN_PORT="${PORT:-10000}"
sed -e "s/__LISTEN_PORT__/${LISTEN_PORT}/g" -e "s/__GODOT_PORT__/${GODOT_PORT}/g" /app/nginx.conf.template > /etc/nginx/nginx.conf
env GODOT_PORT="$GODOT_PORT" /app/server --headless &
exec nginx -g "daemon off;"
