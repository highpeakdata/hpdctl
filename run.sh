#!/bin/sh
#
# Run hpdctl in a container
#
# This script will attempt to mirror the host paths by using volumes for the
# following paths:
#   * $(pwd)
#   * $(dirname $YAML_FILE) if it's set
#   * $HOME if it's set
#
# You can add additional volumes (or any docker run options) using
# the $HPDCTL_OPTIONS environment variable.
#


set -e

VERSION="0.0.248"
IMAGE="edgefs/hpdctl:$VERSION"


# Setup options for connecting to docker host
if [ -z "$DOCKER_HOST" ]; then
    DOCKER_HOST="/var/run/docker.sock"
fi
if [ -S "$DOCKER_HOST" ]; then
    DOCKER_ADDR="-v $DOCKER_HOST:$DOCKER_HOST -e DOCKER_HOST"
else
    DOCKER_ADDR="-e DOCKER_HOST -e DOCKER_TLS_VERIFY -e DOCKER_CERT_PATH"
fi


# Setup volume mounts for hpdctl config and context
if [ "$(pwd)" != '/' ]; then
    VOLUMES="-v $(pwd):$(pwd)"
fi
if [ -n "$YAML_FILE" ]; then
    HPDCTL_OPTIONS="$HPDCTL_OPTIONS -e YAML_FILE=$YAML_FILE"
    hpdctl_dir=$(realpath $(dirname $YAML_FILE))
fi
# TODO: also check --file argument
if [ -n "$hpdctl_dir" ]; then
    VOLUMES="$VOLUMES -v $hpdctl_dir:$hpdctl_dir"
fi
if [ -n "$HOME" ]; then
    VOLUMES="$VOLUMES -v $HOME:$HOME -v $HOME:/root" # mount $HOME in /root to share docker.config
fi

# Only allocate tty if we detect one
if [ -t 0 -a -t 1 ]; then
        DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -t"
fi

# Always set -i to support piped and terminal input in run/exec
DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS -i"


# Handle userns security
if [ ! -z "$(docker info 2>/dev/null | grep userns)" ]; then
    DOCKER_RUN_OPTIONS="$DOCKER_RUN_OPTIONS --userns=host"
fi

exec docker run --rm $DOCKER_RUN_OPTIONS $DOCKER_ADDR $HPDCTL_OPTIONS $VOLUMES -w "$(pwd)" $IMAGE "$@"
