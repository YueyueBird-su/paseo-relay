#!/bin/sh
set -eu

lan_script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
lan_repo_root=$(CDPATH= cd -- "$lan_script_dir/../.." && pwd)
lan_output_dir=${1:-$lan_repo_root/dist}
lan_os=$(uname -s | tr '[:upper:]' '[:lower:]')
lan_arch=$(uname -m)
lan_name="agentero-lan-relay-$lan_os-$lan_arch"
lan_stage=$(mktemp -d "${TMPDIR:-/tmp}/agentero-relay-package.XXXXXX")
trap 'rm -rf "$lan_stage"' EXIT HUP INT TERM

cd "$lan_repo_root"
MIX_ENV=prod mix release --overwrite
mkdir -p "$lan_output_dir" "$lan_stage/$lan_name/deployment/lan"
cp -R _build/prod/rel/paseo_relay "$lan_stage/$lan_name/release"
# A public download must not contain the builder's distribution credential.
rm -f "$lan_stage/$lan_name/release/releases/COOKIE"
cp LICENSE "$lan_stage/$lan_name/LICENSE"
cp deployment/lan/run.sh deployment/lan/README.md "$lan_stage/$lan_name/deployment/lan/"
cat > "$lan_stage/$lan_name/start.command" <<'LAUNCHER'
#!/bin/sh
set -eu
lan_bundle_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export PASEO_RELAY_RELEASE_ROOT="$lan_bundle_root/release"
exec "$lan_bundle_root/deployment/lan/run.sh"
LAUNCHER
chmod +x "$lan_stage/$lan_name/start.command" "$lan_stage/$lan_name/deployment/lan/run.sh"
tar -czf "$lan_output_dir/$lan_name.tar.gz" -C "$lan_stage" "$lan_name"
printf '%s\n' "$lan_output_dir/$lan_name.tar.gz"
