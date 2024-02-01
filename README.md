# Opensearch Docker Container Image

[![Build Status](https://github.com/wodby/opensearch/workflows/Build%20docker%20image/badge.svg)](https://github.com/wodby/opensearch/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/wodby/opensearch.svg)](https://hub.docker.com/r/wodby/opensearch)
[![Docker Stars](https://img.shields.io/docker/stars/wodby/opensearch.svg)](https://hub.docker.com/r/wodby/opensearch)

## Docker Images

❗For better reliability we release images with stability tags (`wodby/opensearch:7-X.X.X`) which correspond to [git tags](https://github.com/wodby/opensearch/releases). We strongly recommend using images only with stability tags. 

Overview:

- All images based on Alpine Linux
- Base image: [wodby/openjdk](https://github.com/wodby/openjdk)
- [GitHub actions builds](https://github.com/wodby/opensearch/actions)
- [Docker Hub](https://hub.docker.com/r/wodby/opensearch)

Supported tags and respective `Dockerfile` links:

- `7.17`, `7`, `latest` [_(Dockerfile)_](https://github.com/wodby/opensearch/tree/master/Dockerfile)
- `6.8`, `6` [_(Dockerfile)_](https://github.com/wodby/opensearch/tree/master/Dockerfile)

## Environment Variables

| Variable                                      | Default Value           | Description                                    |
|-----------------------------------------------|-------------------------|------------------------------------------------|
| `OS_BOOTSTRAP_MEMORY_LOCK`                    | `true`                  |                                                |
| `OS_CLUSTER_NAME`                             | `opensearch-default` |                                                |
| `OS_DISCOVERY_ZEN_MINIMUM_MASTER_NODES`       | `1`                     | 6.x only                                       |
| `OS_HTTP_CORS_ALLOW_ORIGIN`                   | `*`                     |                                                |
| `OS_HTTP_CORS_ENABLED`                        | `true`                  |                                                |
| `OS_HTTP_ENABLED`                             | `true`                  | 6.x only                                       |
| `OS_JAVA_OPTS`                                | `-Xms1g -Xmx1g`         |                                                |
| `OS_NETWORK_HOST`                             | `0.0.0.0`               |                                                |
| `OS_NODE_DATA`                                | `true`                  |                                                |
| `OS_NODE_INGEST`                              | `true`                  |                                                |
| `OS_NODE_MASTER`                              | `true`                  |                                                |
| `OS_NODE_MAX_LOCAL_STORAGE_NODES`             | `1`                     |                                                |
| `OS_PLUGINS_INSTALL`                          |                         | Install specified plugins (separated by comma) |
| `OS_SHARD_ALLOCATION_AWARENESS_ATTR_FILEPATH` |                         |                                                |
| `OS_SHARD_ALLOCATION_AWARENESS_ATTR`          |                         |                                                |
| `OS_STORAGE_TEMP`                             |                         | e.g. `warm` or `hot` for implementing a        |
|                                               |                         | hot-warm architecture                          |
| `OS_TRANSPORT_HOST`                           | `localhost`             |                                                |

## Orchestration Actions

Usage:
```
make COMMAND [params ...]
 
commands:
    check-ready [host max_try wait_seconds delay_seconds]
 
default params values:
    host localhost
    max_try 1
    wait_seconds 1
    delay_seconds 0
```

## Deployment

Deploy Opensearch with Opensearch-Dashboards to your own server via [![Wodby](https://www.google.com/s2/favicons?domain=wodby.com) Wodby](https://wodby.com/stacks/opensearch).

## Upgrading

To upgrade the underlying version of Opensearch, edit `version` and `tags` in `.github/workflows/workflow.yml`:

```
     - uses: actions/checkout@v2
     - uses: ./.github/actions
       with:
        version: '1.3.12'
        tags: 1.3.12,1.3,1,latest
```

To finalize the release, add an increasing stability tag:

```
git commit -m "Upgrade Opensearch to 1.3.12" .
git tag -m "Upgrade Opensearch to 1.3.12" 1.0.9
git push && git push --tags

```

The resulting image will be available as `ghcr.io/ramsalt/opensearch:1.3.12-1.0.9'
