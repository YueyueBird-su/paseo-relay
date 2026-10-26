#!/bin/sh
set -eu

lan_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
lan_repo_root=$(CDPATH= cd -- "$lan_script_dir/../.." && pwd)
lan_release_root=${PASEO_RELAY_RELEASE_ROOT:-$lan_repo_root/_build/prod/rel/paseo_relay}

# This private deployment uses the operator's fixed overlay-network address.
# Override the host when packaging for a different machine or interface.
export PASEO_RELAY_HOST=${PASEO_RELAY_HOST:-10.112.112.93}
export PASEO_RELAY_PORT=${PASEO_RELAY_PORT:-4000}
export PASEO_RELAY_ALLOW_LEGACY_BASE64URL=${PASEO_RELAY_ALLOW_LEGACY_BASE64URL:-true}
export PASEO_RELAY_MIN_CLUSTER_SIZE=${PASEO_RELAY_MIN_CLUSTER_SIZE:-1}

exec "$lan_release_root/bin/paseo_relay" start
