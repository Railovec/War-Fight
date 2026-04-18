# syntax=docker/dockerfile:1
ARG GODOT_VERSION=4.5
ARG GODOT_RELEASE=stable

# Build-headless Godot export (used by the default image for Render)
FROM ubuntu:22.04 AS builder
ARG GODOT_VERSION
ARG GODOT_RELEASE
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates wget unzip \
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
COPY . /project
WORKDIR /project
RUN rm -rf build && mkdir -p build && godot --headless --export-release "Linux" ./build/server.x86_64

# Local / CI: ship a binary produced outside Docker (e.g. GitHub Actions godot export)
FROM debian:bookworm-slim AS runtime-standalone
RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates \
	libfontconfig1 \
	libstdc++6 \
	&& rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY build/server.x86_64 /app/server
RUN chmod +x /app/server
ENV PORT=9080
EXPOSE 9080
CMD ["/app/server", "--headless"]

# Render: nginx on $PORT (HTTP /health + WebSocket proxy) → Godot on GODOT_PORT
FROM debian:bookworm-slim AS runtime-render
RUN apt-get update && apt-get install -y --no-install-recommends \
	ca-certificates \
	libfontconfig1 \
	libstdc++6 \
	nginx \
	&& rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /project/build/server.x86_64 /app/server
COPY docker/nginx.conf.template /app/nginx.conf.template
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /app/server /entrypoint.sh \
	&& rm -f /etc/nginx/sites-enabled/default
ENV GODOT_PORT=8081
EXPOSE 10000
ENTRYPOINT ["/entrypoint.sh"]
