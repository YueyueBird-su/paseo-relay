# Private LAN / overlay-network relay

Build and start from the repository:

```sh
MIX_ENV=prod mix release
./deployment/lan/run.sh
```

The launcher defaults to `10.112.112.91:4000` and explicitly enables legacy
Agentero Base64URL compatibility. Generic release defaults remain unchanged.
The address must actually belong to the host; configure a static overlay IP
before starting. Override `PASEO_RELAY_HOST` for a different machine/interface.

This deployment intentionally does not listen on all interfaces. Overlay
clients must have the appropriate network membership and route to
`ws://10.112.112.91:4000`. The QR offer contains
one reachable endpoint; it does not automatically discover or switch networks.

Package the native release on its target OS/architecture:

```sh
./deployment/lan/package.sh /absolute/output/directory
```

On Windows use `./deployment/lan/package.ps1` in PowerShell. The generated ZIP
contains `start.cmd`; Unix archives contain `start.sh` (plus `start.command` on
macOS). Windows needs the Microsoft Visual C++ Runtime. Linux releases need
system libraries compatible with the build runner (Ubuntu 22.04 x64 or 24.04
arm64); these archives are not static binaries for arbitrary distributions.

Extract the archive and run `start.command`. It uses bundled ERTS; it does not
include pairing identities, Vaults, or machine-specific Git credentials.
Only run one relay per listening port. A standalone archive stays in the
foreground until interrupted. Configure a user service separately if needed.

Public archives omit the build-time Erlang distribution cookie. This adapter
defaults to `RELEASE_DISTRIBUTION=none` and generates a fresh runtime cookie
with the system `openssl` command. For deliberate distributed operation, supply
your own `RELEASE_DISTRIBUTION` and `RELEASE_COOKIE`; generic release behavior
is unchanged.

## GitHub builds

`LAN relay packages` builds and boots each native archive on macOS arm64/x64,
Linux x64/arm64 and Windows x64, then exercises real v2 WebSocket traffic.
Related pushes to `codex/lan-ws-relay` upload Actions artifacts for 14 days.
Push a new `lan-relay-*` tag at a commit containing this workflow to publish
all five packages and SHA256SUMS as a prerelease after every platform passes.
For example, `lan-relay-2026.10.27.1` is separate from the original manually
uploaded `lan-relay-2026.10.27` artifact. Manual dispatch requires the workflow
on the default branch; branch/tag pushes do not require changing that branch.
