# syntax=docker/dockerfile:1
ARG GODOT_VERSION=4.5
ARG GODOT_RELEASE=stable

# Build-headless Godot export (used by the default image for Render)
FROM ubuntu:22.04 AS builder
ARG GODOT_VERSION
ARG GODOT_RELEASE
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/root
RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates wget unzip \
	libfontconfig1 libfreetype6 libstdc++6 \
	libgl1 libglib2.0-0 libdbus-1-3 \
	libx11-6 libxcb1 libxext6 libxinerama1 libxcursor1 libxi6 libxrandr2 \
	&& rm -rf /var/lib/apt/lists/*
WORKDIR /tools
RUN REL="${GODOT_VERSION}-${GODOT_RELEASE}" \
	&& wget -q "https://github.com/godotengine/godot-builds/releases/download/${REL}/Godot_v${REL}_linux.x86_64.zip" -O godot.zip \
	&& unzip -q godot.zip \
	&& chmod +x "Godot_v${REL}_linux.x86_64" \
	&& mv "Godot_v${REL}_linux.x86_64" /usr/local/bin/godot \
	&& wget -q "https://github.com/godotengine/godot-builds/releases/download/${REL}/Godot_v${REL}_export_templates.tpz" -O templates.tpz \
	&& unzip -q templates.tpz \
	&& mkdir -p "/root/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_RELEASE}" \
	&& mv templates/* "/root/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_RELEASE}/" \
	&& rm -rf templates godot.zip templates.tpz
# Build context must be the repo root (see render.yaml dockerContext). Explicit COPY avoids empty/wrong context.
COPY Server/ /project
WORKDIR /project
# Single export. LIBGL_ALWAYS_SOFTWARE: Mesa llvmpipe if Godot needs a GL context during export.
ENV LIBGL_ALWAYS_SOFTWARE=1
RUN set -eu \
	&& echo "---- /project (expect project.godot here) ----" \
	&& ls -la \
	&& test -f project.godot || ( \
		echo "Missing project.godot. Commit and push Server/project.godot, or set Docker build context to repo root." >&2; \
		exit 1 \
	) \
	&& rm -rf build \
	&& mkdir -p build \
	&& godot --verbose --headless --export-release "Linux" build/server.x86_64 \
	&& test -f build/server.x86_64

# Local / CI: ship a binary produced outside Docker (e.g. GitHub Actions godot export)
FROM debian:bookworm-slim AS runtime-standalone
RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates \
	libfontconfig1 \
	libstdc++6 \
	&& rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY Server/build/server.x86_64 /app/server
RUN chmod +x /app/server
ENV PORT=9080
EXPOSE 9080
CMD ["/app/server", "--headless"]

# Render: nginx on $PORT (HTTP /health + WebSocket proxy) → Godot on GODOT_PORT (no extra repo files required)
FROM debian:bookworm-slim AS runtime-render
RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates \
	libfontconfig1 \
	libstdc++6 \
	nginx \
	&& rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /project/build/server.x86_64 /app/server
RUN chmod +x /app/server \
	&& rm -f /etc/nginx/sites-enabled/default \
	&& cat > /app/nginx.conf.template <<'EOF'
user www-data;
worker_processes auto;
error_log /dev/stderr warn;
pid /tmp/nginx.pid;
events {
	worker_connections 1024;
}
http {
	include /etc/nginx/mime.types;
	default_type application/octet-stream;
	map $http_upgrade $connection_upgrade {
		default upgrade;
		'' close;
	}
	server {
		listen __LISTEN_PORT__;
		location /health {
			access_log off;
			return 200 "ok\n";
			add_header Content-Type text/plain;
		}
		# Godot only accepts WebSocket handshakes; plain GET/HEAD (probes, browsers) must not hit upstream.
		location / {
			if ($http_upgrade != "websocket") {
				default_type text/plain;
				return 200 "WebSocket endpoint — use wss:// with a WebSocket client.\n";
			}
			proxy_pass http://127.0.0.1:__GODOT_PORT__;
			proxy_http_version 1.1;
			proxy_set_header Upgrade $http_upgrade;
			proxy_set_header Connection $connection_upgrade;
			proxy_set_header Host $host;
			proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
			proxy_set_header X-Forwarded-Proto $scheme;
			proxy_read_timeout 86400;
			proxy_send_timeout 86400;
		}
	}
}
EOF
RUN cat > /entrypoint.sh <<'EOF'
#!/bin/sh
set -e
GODOT_PORT="${GODOT_PORT:-8081}"
LISTEN_PORT="${PORT:-10000}"
sed -e "s/__LISTEN_PORT__/${LISTEN_PORT}/g" -e "s/__GODOT_PORT__/${GODOT_PORT}/g" /app/nginx.conf.template > /etc/nginx/nginx.conf
env GODOT_PORT="$GODOT_PORT" /app/server --headless &
exec nginx -g "daemon off;"
EOF
RUN chmod +x /entrypoint.sh
ENV GODOT_PORT=8081
EXPOSE 10000
ENTRYPOINT ["/entrypoint.sh"]
