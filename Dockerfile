# Dockerfile - alpine

ARG RESTY_IMAGE_BASE="openresty/openresty"
ARG RESTY_IMAGE_TAG="1.15.8.2-1-alpine"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

LABEL maintainer="qwzhou89"

# Docker Build Arguments
ARG RESTY_WS_VERSION="0.07"
ARG RESTY_HC_VERSION="0.14"
ARG RESTY_HTTP_VERSION="0.14"
ARG LUA_WAF_VERSION="0.7.3"
ARG LUA_WAF_PATH="/usr/local/openresty/ngx_lua_waf"
ARG NGX_CONF_FILE_PATH="/usr/local/openresty/nginx/conf/nginx.conf"

LABEL RESTY_WS_VERSION="${RESTY_WS_VERSION}"
LABEL RESTY_HC_VERSION="${RESTY_HC_VERSION}"
LABEL RESTY_HTTP_VERSION="${RESTY_HTTP_VERSION}"
LABEL LUA_WAF_VERSION="${LUA_WAF_VERSION}"


# 1) Install apk dependencies
# 2) Download and untar lua-resty-websocket, PCRE, and OpenResty
# 3) Cleanup
# 4) Copy swtc node nginx config file

RUN apk add --no-cache --virtual .build-deps \
        curl \
    && apk add --no-cache \
    && cd /tmp \
    && curl -fSL https://github.com/qwzhou89/lua-resty-upstream-healthcheck/archive/v${RESTY_HC_VERSION}.tar.gz -o lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}.tar.gz \
    && tar xzf lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}.tar.gz \
    && cp -r lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}/lib /usr/local/openresty/ \
    && curl -fSL https://github.com/ledgetech/lua-resty-http/archive/v${RESTY_HTTP_VERSION}.tar.gz -o lua-resty-http-${RESTY_HTTP_VERSION}.tar.gz \
    && tar xzf lua-resty-http-${RESTY_HTTP_VERSION}.tar.gz \
    && cp -r lua-resty-http-${RESTY_HTTP_VERSION}/lib /usr/local/openresty/ \
    && curl -fSL https://github.com/qwzhou89/ngx_lua_waf/archive/v${LUA_WAF_VERSION}.tar.gz -o ngx_lua_waf-${LUA_WAF_VERSION}.tar.gz \
    && tar xzf ngx_lua_waf-${LUA_WAF_VERSION}.tar.gz \
    && mkdir -p ${LUA_WAF_PATH}/logs/hack \
    && chown -R 65534:65534 ${LUA_WAF_PATH}/logs/hack \
    && cp -r ngx_lua_waf-${LUA_WAF_VERSION}/*.lua ${LUA_WAF_PATH} \
    && cp -r ngx_lua_waf-${LUA_WAF_VERSION}/wafconf ${LUA_WAF_PATH} \
    && sed -i "/worker_processes/aworker_shutdown_timeout  5;" ${NGX_CONF_FILE_PATH} \
    && sed -i "s@worker_connections  1024@worker_connections  102400@" ${NGX_CONF_FILE_PATH} \
    && sed -i "s@/usr/local/nginx/conf/waf@${LUA_WAF_PATH}@" ${LUA_WAF_PATH}/config.lua \
    && sed -i "s@/usr/local/nginx/logs@${LUA_WAF_PATH}/logs@" ${LUA_WAF_PATH}/config.lua \
    && echo $'\nlocal process = require "ngx.process"\n\
local ok, err = process.enable_privileged_agent()\n\
if not ok then\n\
    ngx.log(ngx.ERR, "enables privileged agent failed error:", err)\n\
end\n'\
>> ${LUA_WAF_PATH}/init.lua \
    && rm -rf \
        lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}.tar.gz lua-resty-upstream-healthcheck-${RESTY_HC_VERSION} \
        lua-resty-http-${RESTY_HTTP_VERSION}.tar.gz lua-resty-http-${RESTY_HTTP_VERSION} \
        ngx_lua_waf-${LUA_WAF_VERSION}.tar.gz ngx_lua_waf-${LUA_WAF_VERSION} \
    && apk del .build-deps

# Copy nginx configuration files
COPY swtcnode.default.conf /etc/nginx/conf.d/swtcnode.conf
COPY ws_servers /etc/nginx/conf.d/ws_servers

EXPOSE 5020
# CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# STOPSIGNAL SIGQUIT
