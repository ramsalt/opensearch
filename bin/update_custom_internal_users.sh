#!/bin/bash
set -euo pipefail

cd /usr/share/opensearch

bash plugins/opensearch-security/tools/securityadmin.sh \
    -f config/opensearch-security/internal_users.yml \
    -icl -nhnv \
    -cacert config/root-ca.pem \
    -cert config/admin.pem \
    -key config/admin-key.pem \
    -t internalusers

bash plugins/opensearch-security/tools/securityadmin.sh \
    -f config/opensearch-security/roles.yml \
    -icl -nhnv \
    -cacert config/root-ca.pem \
    -cert config/admin.pem \
    -key config/admin-key.pem \
    -t roles

bash plugins/opensearch-security/tools/securityadmin.sh \
    -f config/opensearch-security/roles_mapping.yml \
    -icl -nhnv \
    -cacert config/root-ca.pem \
    -cert config/admin.pem \
    -key config/admin-key.pem \
    -t rolesmapping
