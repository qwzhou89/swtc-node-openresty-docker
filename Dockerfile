# Dockerfile - alpine

ARG RESTY_IMAGE_BASE="openresty/openresty"
ARG RESTY_IMAGE_TAG="1.15.8.2-1-alpine"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

LABEL maintainer="qwzhou89"

# Docker Build Arguments
ARG RESTY_WS_VERSION="0.07"
ARG RESTY_HC_VERSION="0.11"

LABEL resty_ws_version="${RESTY_WS_VERSION}"
LABEL resty_hc_version="${RESTY_HC_VERSION}"

# 1) Install apk dependencies
# 2) Download and untar lua-resty-websocket, PCRE, and OpenResty
# 3) Cleanup
# 4) Copy swtc node nginx config file

RUN apk add --no-cache --virtual .build-deps \
        curl \
    && apk add --no-cache \
    && cd /tmp \
    && curl -fSL https://github.com/openresty/lua-resty-websocket/archive/v${RESTY_WS_VERSION}.tar.gz -o lua-resty-websocket-${RESTY_WS_VERSION}.tar.gz \
    && tar xzf lua-resty-websocket-${RESTY_WS_VERSION}.tar.gz \
    && cp -r lua-resty-websocket-${RESTY_WS_VERSION}/lib /usr/local/openresty/ \
    && curl -fSL https://github.com/qwzhou89/lua-resty-upstream-healthcheck/archive/v${RESTY_HC_VERSION}.tar.gz -o lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}.tar.gz \
    && tar xzf lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}.tar.gz \
    && cp -r lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}/lib /usr/local/openresty/ \
    && rm -rf \
        lua-resty-websocket-${RESTY_WS_VERSION}.tar.gz lua-resty-websocket-${RESTY_WS_VERSION} \
        lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}.tar.gz lua-resty-upstream-healthcheck-${RESTY_HC_VERSION} \
    && apk del .build-deps

# Copy nginx configuration files
COPY swtcnode.default.conf /etc/nginx/conf.d/swtcnode.conf

# CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# STOPSIGNAL SIGQUIT
