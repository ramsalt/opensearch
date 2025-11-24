#!/bin/bash
set -euo pipefail

CURL="curl -ksS --fail-with-body --cert ./config/admin.pem --key ./config/admin-key.pem --cacert config/root-ca.pem"
CT='--header Content-type:application/json'
OS="https://localhost:9200"

VERSION_X="${1:-1}"

echo
echo "Indices created with version ${VERSION_X}.x.y:"
echo

${CURL} ${CT} "${OS}/*/_settings?expand_wildcards=all&include_defaults=false&human" \
        | jq -r '. | to_entries | .[] | select(.value.settings.index.version.created_string | test("^'"${VERSION_X}"'")) | .key + "\t" + .value.settings.index.version.created_string' \
        | sort

echo
echo "These indices will need to be re-index before upgrading to the next major version!"
