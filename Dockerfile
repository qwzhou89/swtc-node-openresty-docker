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
    && curl -fSL https://github.com/openresty/lua-resty-websocket/archive/v${RESTY_WS_VERSION}.tar.gz -o lua-resty-websocket-${RESTY_WS_VERSION}.tar.gz \
    && tar xzf lua-resty-websocket-${RESTY_WS_VERSION}.tar.gz \
    && cp -r lua-resty-websocket-${RESTY_WS_VERSION}/lib /usr/local/openresty/ \
    && curl -fSL https://github.com/qwzhou89/lua-resty-upstream-healthcheck/archive/v${RESTY_HC_VERSION}.tar.gz -o lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}.tar.gz \
    && tar xzf lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}.tar.gz \
    && cp -r lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}/lib /usr/local/openresty/ \
    && curl -fSL https://github.com/ledgetech/lua-resty-http/archive/v${RESTY_HTTP_VERSION}.tar.gz -o lua-resty-http-${RESTY_HTTP_VERSION}.tar.gz \
    && tar xzf lua-resty-http-${RESTY_HTTP_VERSION}.tar.gz \
    && cp -r lua-resty-http-${RESTY_HTTP_VERSION}/lib /usr/local/openresty/ \
    && curl -fSL https://github.com/qwzhou89/ngx_lua_waf/archive/v${LUA_WAF_VERSION}.tar.gz -o ngx_lua_waf-${LUA_WAF_VERSION}.tar.gz \
    && tar xzf ngx_lua_waf-${LUA_WAF_VERSION}.tar.gz \
    && mkdir -p /usr/local/openresty/ngx_lua_waf \
    && cp -r ngx_lua_waf-${LUA_WAF_VERSION}/*.lua /usr/local/openresty/ngx_lua_waf \
    && cp -r ngx_lua_waf-${LUA_WAF_VERSION}/wafconf /usr/local/openresty/ngx_lua_waf \
    && sed -i 's@/usr/local/nginx/conf/waf@/usr/local/openresty/ngx_lua_waf@' /usr/local/openresty/ngx_lua_waf/config.lua \
    && sed -i 's@/usr/local/nginx/logs@/usr/local/openresty/nginx/logs@' /usr/local/openresty/ngx_lua_waf/config.lua \
    && echo 'local process = require "ngx.process"
local ok, err = process.enable_privileged_agent()
if not ok then
    ngx.log(ngx.ERR, "enables privileged agent failed error:", err)
end
' >> /usr/local/openresty/ngx_lua_waf/init.lua \
    && rm -rf \
        lua-resty-websocket-${RESTY_WS_VERSION}.tar.gz lua-resty-websocket-${RESTY_WS_VERSION} \
        lua-resty-upstream-healthcheck-${RESTY_HC_VERSION}.tar.gz lua-resty-upstream-healthcheck-${RESTY_HC_VERSION} \
        lua-resty-http-${RESTY_HTTP_VERSION}.tar.gz lua-resty-http-${RESTY_HTTP_VERSION} \
        ngx_lua_waf-${LUA_WAF_VERSION}.tar.gz ngx_lua_waf-${LUA_WAF_VERSION} \
    && apk del .build-deps

# Copy nginx configuration files
COPY swtcnode.default.conf /etc/nginx/conf.d/swtcnode.conf
COPY ws_servers /etc/nginx/conf.d/ws_servers
COPY wss_servers /etc/nginx/conf.d/wss_servers
COPY rpc_servers /etc/nginx/conf.d/rpc_servers
COPY fullchain.pem /etc/nginx/conf.d/fullchain.pem
COPY privkey.pem /etc/nginx/conf.d/privkey.pem

EXPOSE 5020 5050 5028
# CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# STOPSIGNAL SIGQUIT
