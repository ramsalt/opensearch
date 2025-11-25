#!/bin/bash
set -euo pipefail

CURL="curl -ksS --fail-with-body --cert ./config/admin.pem --key ./config/admin-key.pem --cacert config/root-ca.pem"
CT='--header Content-type:application/json'
OS="https://localhost:9200"
TMP_PREFIX=".temp"

INDEX="${1:-}"
TMP_INDEX="${TMP_PREFIX}-${INDEX}"

if [ -z "${INDEX}" ]; then
    echo -e "Usage:\n\t$0 INDEX\n"
    exit 2
fi

# retrieve possible aliases pointing to this index
ALIASES=$(${CURL} ${CT} "${OS}/${INDEX}/*" \
    | jq -r ".[].aliases | keys | .[]")

# re-index into temporary index
echo "Reindexing into temporary index ${TMP_INDEX}..."
${CURL} -X POST ${CT} "${OS}/_reindex?pretty&wait_for_completion=true" -d '
{
  "source":{
    "index": "'"${INDEX}"'"
  },
  "dest":{
    "index": "'"${TMP_INDEX}"'"
  }
}'

WAIT=1
echo -n "Waiting"
while [ "${WAIT}" -gt "0" ]; do
    echo -n .
    sleep 0.5
    WAIT=$(${CURL} ${CT} "${OS}/_cat/recovery/${TMP_INDEX}?active_only=true&format=json" | jq -r "length")
done
echo

# delete original index
echo "Deleting original index..."
${CURL} -X DELETE ${CT} "${OS}/${INDEX}?pretty"

# re-index into original table
echo "Reindexing into orginal table..."
${CURL} -X POST ${CT} "${OS}/_reindex?pretty&wait_for_completion=true" -d '
{
  "source":{
    "index": "'"${TMP_INDEX}"'"
  },
  "dest":{
    "index": "'"${INDEX}"'"
  }
}'

WAIT=1
echo -n "Waiting"
while [ "${WAIT}" -gt "0" ]; do
    echo -n .
    sleep 0.5
    WAIT=$(${CURL} ${CT} "${OS}/_cat/recovery/${INDEX}?active_only=true&format=json" | jq -r "length")
done
echo

# fix aliases
for ALIAS in ${ALIASES}; do
    echo "Recreating alias ${ALIAS}..."
    ${CURL} -X POST ${CT} "${OS}/_aliases?pretty" -d '
    {
      "actions": [
        {
          "add": {
            "index": "'"${INDEX}"'",
            "alias": "'"${ALIAS}"'"
          }
        }
      ]
    }'
done

# delete temporary index
echo "Deleting temporary index..."
${CURL} -X DELETE ${CT} "${OS}/${TMP_INDEX}?pretty"

echo "Done."
