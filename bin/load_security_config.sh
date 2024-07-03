#!/bin/bash
set -euo pipefail

cd /usr/share/opensearch

bash plugins/opensearch-security/tools/securityadmin.sh \
    -f config/opensearch-security/config.yml \
    -icl -nhnv \
    -cacert config/root-ca.pem \
    -cert config/admin.pem \
    -key config/admin-key.pem \
    -t config
