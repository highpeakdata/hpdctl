#!/bin/sh
#
# Run hpdctl in a container
#
# This script will attempt to mirror the host paths by using volumes for the
# following paths:
#   * $(pwd)
#   * $HOME if it's set to store jwt tokens
#
# You can add additional volumes (or any docker run options) using
# the $HPDCTL_OPTIONS environment variable.
#


set -e

VERSION="0.0.249"
IMAGE="edgefs/hpdctl:$VERSION"

# Setup volume mounts for hpdctl config and context
if [ "$(pwd)" != '/' ]; then
    VOLUMES="-v $(pwd):$(pwd)"
fi

if [ -n "$HOME" ]; then
    VOLUMES="$VOLUMES -v $HOME:$HOME"
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

#echo "docker run --rm $DOCKER_RUN_OPTIONS $HPDCTL_OPTIONS $VOLUMES -w "$(pwd)" $IMAGE -p hpdconnect.highpeakdata:30000 \"$@\""
exec docker run --rm $DOCKER_RUN_OPTIONS $HPDCTL_OPTIONS $VOLUMES -w "$(pwd)" $IMAGE -p hpdconnect.highpeakdata.com:30000 "$@"
