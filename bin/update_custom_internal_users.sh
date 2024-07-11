#!/bin/bash
set -euo pipefail

cd /usr/share/opensearch

# both ADMIN_PASSWORD and READONLY_PASSWORD must be set, otherwise this is skipped
[ -z "$ADMIN_PASSWORD" ] && exit 0
[ -z "$READONLY_PASSWORD" ] && exit 0

cat > config/opensearch-security/custom_internal_users.yml <<_EOF_
---
_meta:
  type: "internalusers"
  config_version: 2

admin:
    hash: "$(bash plugins/opensearch-security/tools/hash.sh -env ADMIN_PASSWORD)"
    reserved: true
    backend_roles:
    - "admin"
    description: "Admin user"

dashboards:
    hash: "$(bash plugins/opensearch-security/tools/hash.sh -env READONLY_PASSWORD)"
    reserved: true
    backend_roles:
    - "kibanauser"
    - "readall"
    description: "Read-only user"
_EOF_

bash plugins/opensearch-security/tools/securityadmin.sh \
    -f config/opensearch-security/custom_internal_users.yml \
    -icl -nhnv \
    -cacert config/root-ca.pem \
    -cert config/admin.pem \
    -key config/admin-key.pem \
    -t internalusers

cat > config/opensearch-security/custom_roles.yml <<_EOF_
---
_meta:
  type: "roles"
  config_version: 2

anonymous_users_role:
  reserved: false
  hidden: false
  cluster_permissions:
  - "OPENDISTRO_SECURITY_CLUSTER_COMPOSITE_OPS"
  index_permissions:
  - index_patterns:
    - "registrations-*"
    allowed_actions:
    - "read"
_EOF_

bash plugins/opensearch-security/tools/securityadmin.sh \
    -f config/opensearch-security/custom_roles.yml \
    -icl -nhnv \
    -cacert config/root-ca.pem \
    -cert config/admin.pem \
    -key config/admin-key.pem \
    -t roles
