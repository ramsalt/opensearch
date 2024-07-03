ARG BASE_IMAGE_TAG

FROM eclipse-temurin:${BASE_IMAGE_TAG}

ARG OPENSEARCH_VER

ENV OPENSEARCH_VER="${OPENSEARCH_VER}" \
    OPENSEARCH_JAVA_OPTS="-Xms1g -Xmx1g" \
    OS_TMPDIR="/tmp" \
    \
    LANG="C.UTF-8" \
    \
    PATH="${PATH}:/usr/share/opensearch/bin" \
    \
    ADMIN_PASSWORD=admin \
    READONLY_PASSWORD=changeme

RUN set -ex; \
    { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home; \
	chmod +x /usr/local/bin/docker-java-home; \
    \
    addgroup -g 1000 -S opensearch; \
    adduser -u 1000 -D -S -s /bin/bash -G opensearch opensearch; \
    echo "PS1='\w\$ '" >> /home/opensearch/.bashrc; \
    \
    apk add --update --no-cache -t .es-rundeps \
        bash \
        make \
        curl \
        su-exec \
        util-linux; \
    \
    apk add --no-cache -t .es-build-deps gnupg openssl git tar; \
    \
    gotpl_url="https://github.com/wodby/gotpl/releases/download/0.1.5/gotpl-alpine-linux-amd64-0.1.5.tar.gz"; \
    wget -qO- "${gotpl_url}" | tar xz -C /usr/local/bin; \
    git clone https://github.com/wodby/alpine /tmp/alpine; \
    cd /tmp/alpine; \
    latest=$(git describe --abbrev=0 --tags); \
    git checkout "${latest}"; \
    mv /tmp/alpine/bin/* /usr/local/bin; \
    es_url="https://artifacts.opensearch.org/releases/bundle/opensearch/${OPENSEARCH_VER}/opensearch-${OPENSEARCH_VER}"; \
    [[ $(compare_semver "${OPENSEARCH_VER}" "1.3") == 0 ]] && es_url="${es_url}-linux-x64"; \
    es_url="${es_url}.tar.gz"; \
    \
    cd /tmp; \
    [ -f es.tar.gz ] || curl -o es.tar.gz -Lskj "${es_url}"; \
    curl -o es.tar.gz.sig -Lskj "${es_url}.sig"; \
    GPG_KEYS=C5B7498965EFD1C2924BA9D539D319879310D3FC gpg_verify /tmp/es.tar.gz.sig /tmp/es.tar.gz; \
    \
    mkdir -p /usr/share/opensearch/data /usr/share/opensearch/logs /snapshots; \
    # https://github.com/elastic/opensearch/issues/49417#issuecomment-557265783
    if tar tf es.tar.gz | head -n 1 | grep -q '^./$'; then \
        STRIP_COMPONENTS_COUNT=2; \
    else \
        STRIP_COMPONENTS_COUNT=1; \
    fi; \
    tar zxf es.tar.gz --strip-components=$STRIP_COMPONENTS_COUNT -C /usr/share/opensearch; \
    \
    chown -R opensearch:opensearch /usr/share/opensearch; \
    \
    apk del --purge .es-build-deps; \
    rm -rf /tmp/*; \
    rm -rf /var/cache/apk/*

# We have to use root as default user to update ulimit.
#USER 1000

RUN apk add --no-cache openssl

WORKDIR /usr/share/opensearch

VOLUME /usr/share/opensearch/data

COPY templates /etc/gotpl/
COPY config /usr/share/opensearch/config/
COPY bin /usr/local/bin/

USER 1000

RUN cd config; \
    ls /usr/bin; \
    generate_certificates.sh; \
    ls -alh /usr/share/opensearch/config/

USER 0

EXPOSE 9200 9300

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["opensearch"]
