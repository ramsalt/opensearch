#!/usr/bin/env bash

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

if [[ -n "${TRAVIS}" ]]; then
    sudo sysctl -w vm.max_map_count=262144
fi

# Since Kubernetes does not support docker's --ulimit param we exec ulimit in entrypoint.
cid="$(docker run -d --name "${NAME}" --cap-add SYS_RESOURCE "${IMAGE}")"
trap "docker rm -vf $cid > /dev/null" EXIT

elasticsearch() {
	docker run --rm -i --link "${NAME}":"elasticsearch" --cap-add SYS_RESOURCE "${IMAGE}" "${@}" host="elasticsearch"
}

elasticsearch make check-ready wait_seconds=5 max_try=12 delay_seconds=20
