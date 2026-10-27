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

Extract the archive and run `start.command`. It uses bundled ERTS; it does not
include pairing identities, Vaults, or machine-specific Git credentials.
Only run one relay per listening port. A standalone archive stays in the
foreground until interrupted. Configure a user service separately if needed.

Public archives omit the build-time Erlang distribution cookie. This adapter
defaults to `RELEASE_DISTRIBUTION=none` and generates a fresh runtime cookie
with the system `openssl` command. For deliberate distributed operation, supply
your own `RELEASE_DISTRIBUTION` and `RELEASE_COOKIE`; generic release behavior
is unchanged.
