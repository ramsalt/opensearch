#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

if [[ "${OS_BOOTSTRAP_MEMORY_LOCK:-true}" == "true" ]]; then
    ulimit -l unlimited
fi

install_plugins() {
    if [[ -n "${OS_PLUGINS_INSTALL}" ]]; then
       IFS=',' read -r -a plugins <<< "${OS_PLUGINS_INSTALL}"
       for plugin in "${plugins[@]}"; do
          if ! opensearch-plugin list | grep -qs "${plugin}"; then
             yes | opensearch-plugin install --batch "${plugin}"
          fi
       done
    fi
}

process_templates() {
    # Get value for shard allocation awareness attributes.
    # https://www.elastic.co/guide/en/elasticsearch/reference/current/allocation-awareness.html#CO287-1
    if [[ -n "${OS_SHARD_ALLOCATION_AWARENESS_ATTR_FILEPATH}" && -n "${OS_SHARD_ALLOCATION_AWARENESS_ATTR}" ]]; then
        if [[ "${NODE_DATA:-true}" == "true" ]]; then
            export OS_SHARD_ATTR=$(cat "${OS_SHARD_ALLOCATION_AWARENESS_ATTR_FILEPATH}")
            export OS_NODE_NAME="${OS_SHARD_ATTR}-${OS_NODE_NAME}"
        fi
    fi

    gotpl "/etc/gotpl/opensearch${OPENSEARCH_VER:0:1}.yml.tmpl" > /usr/share/opensearch/config/opensearch.yml
    gotpl "/etc/gotpl/security.yml.tmpl" > /usr/share/opensearch/config/opensearch-security/config.yml
    gotpl "/etc/gotpl/roles.yml.tmpl" > /usr/share/opensearch/config/opensearch-security/roles.yml
    gotpl "/etc/gotpl/roles_mapping.yml.tmpl" > /usr/share/opensearch/config/opensearch-security/roles_mapping.yml
    gotpl "/etc/gotpl/log4j2.properties.tmpl" > /usr/share/opensearch/config/log4j2.properties

    ADMIN_HASH="$(bash plugins/opensearch-security/tools/hash.sh -env ADMIN_PASSWORD)" \
    READONLY_HASH="$(bash plugins/opensearch-security/tools/hash.sh -env READONLY_PASSWORD)" \
    KIBANASERVER_HASH="$(bash plugins/opensearch-security/tools/hash.sh -env KIBANASERVER_PASSWORD)" \
    gotpl "/etc/gotpl/internal_users.yml.tmpl" > /usr/share/opensearch/config/opensearch-security/internal_users.yml
}

# The virtual file /proc/self/cgroup should list the current cgroup
# membership. For each hierarchy, you can follow the cgroup path from
# this file to the cgroup filesystem (usually /sys/fs/cgroup/) and
# introspect the statistics for the cgroup for the given
# hierarchy. Alas, Docker breaks this by mounting the container
# statistics at the root while leaving the cgroup paths as the actual
# paths. Therefore, Elasticsearch provides a mechanism to override
# reading the cgroup path from /proc/self/cgroup and instead uses the
# cgroup path defined the JVM system property
# es.cgroups.hierarchy.override. Therefore, we set this value here so
# that cgroup statistics are available for the container this process
# will run in.
export OS_JAVA_OPTS="-Des.cgroups.hierarchy.override=/ $OS_JAVA_OPTS"

# Generate random node name if not set.
if [[ -z "${OS_NODE_NAME}" ]]; then

    if [[ -n "${OS_STORAGE_TEMP}" ]]; then

        if [[ "${OS_STORAGE_TEMP}" == "hot" ]]; then
            export OS_NODE_NAME=opensearch
        else
            export OS_NODE_NAME=opensearch-warm-storage
        fi

    else
        export OS_NODE_NAME=$(uuidgen)
    fi
fi

# Fix volume permissions.
chown -R opensearch:opensearch /usr/share/opensearch/data

install_plugins
process_templates

exec_init_scripts

if [[ "${1}" == 'make' ]]; then
    su-exec opensearch "${@}" -f /usr/local/bin/actions.mk
else
    su-exec opensearch "${@}"
fi
