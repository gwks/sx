FROM alpine:latest
ENTRYPOINT ["/sbin/tini","--","/usr/local/searx/dockerfiles/docker-entrypoint.sh"]
EXPOSE 8080
VOLUME /etc/searx
VOLUME /var/log/uwsgi

ENV INSTANCE_NAME=searx \
    SEARX_SETTINGS_PATH=/etc/searx/settings.yml \
    UWSGI_SETTINGS_PATH=/etc/searx/uwsgi.ini \
UPSTREAM_COMMIT=52a21d11925d0aa110563d7ef754e1178d0b5c95

WORKDIR /usr/local/searx

ARG SEARX_GID=977
ARG SEARX_UID=977

RUN addgroup -g ${SEARX_GID} searx && \
    adduser -u ${SEARX_UID} -D -h /usr/local/searx -s /bin/sh -G searx searx

RUN apk upgrade --no-cache \
 && apk add --no-cache -t build-dependencies \
    build-base \
    py3-setuptools \
    python3-dev \
    libffi-dev \
    libxslt-dev \
    libxml2-dev \
    openssl-dev \
    tar \
    git \
 && apk add --no-cache \
    ca-certificates \
    su-exec \
    python3 \
    py3-pip \
    libxml2 \
    libxslt \
    openssl \
    tini \
    uwsgi \
    uwsgi-python3 \
    brotli \
 && git config --global --add safe.directory /usr/local/searx \
 && git clone --depth 1 https://github.com/searx/searx . \
 && git reset --hard ${UPSTREAM_COMMIT} \
 && chown -R searx:searx . \
 && pip3 install --upgrade pip wheel setuptools \
 && pip3 install --no-cache -r requirements.txt \
 && apk del build-dependencies \
 && rm -rf /root/.cache

COPY settings.yml searx/settings.yml

RUN /usr/bin/python3 -m compileall -q searx; \
find /usr/local/searx/searx/static -a \( -name '*.html' -o -name '*.css' -o -name '*.js' -o -name '*.svg' -o -name '*.ttf' -o -name '*.eot' \) \
-type f -exec gzip -9 -k {} \+ -exec brotli --best {} \+
