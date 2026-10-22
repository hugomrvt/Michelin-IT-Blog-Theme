#!/usr/bin/env bash
#
# Run the shared staging Ghost on this machine and publish it over HTTPS with
# Tailscale Funnel, so the Staging workflow (GitHub-hosted runners) and
# reviewers can reach it at https://<machine>.<tailnet>.ts.net.
#
# It is a second Ghost instance, separate from the development one: themes
# only reach it through the Admin API upload done by the Staging workflow,
# never through a symlink to the working tree.
#
# Usage: scripts/ghost-staging.sh <install|start|stop|restart|logs|tunnel|tunnel-off|url>
#
# Environment overrides:
#   GHOST_STAGING_DIR   Ghost install directory (default: ~/ghost-staging)
#   GHOST_STAGING_PORT  Local port              (default: 2369)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export GHOST_DIR="${GHOST_STAGING_DIR:-$HOME/ghost-staging}"
export GHOST_PORT="${GHOST_STAGING_PORT:-2369}"
export GHOST_LINK_THEME=0
export GHOST_PNAME="ghost-staging"
export GHOST_INSTALL_CMD="pnpm staging:install"

die() {
    echo "ghost-staging: $*" >&2
    exit 1
}

tailscale_cli() {
    if command -v tailscale >/dev/null 2>&1; then
        tailscale "$@"
    elif [ -x /Applications/Tailscale.app/Contents/MacOS/Tailscale ]; then
        /Applications/Tailscale.app/Contents/MacOS/Tailscale "$@"
    else
        die "Tailscale is not installed. Install it from https://tailscale.com/download and sign in."
    fi
}

# HTTPS URL of this machine on the tailnet, e.g. https://mac.tail1234.ts.net
public_url() {
    local status name
    status=$(tailscale_cli status --json)
    name=$(printf '%s' "$status" | node -e '
        let raw = "";
        process.stdin.on("data", (chunk) => { raw += chunk; });
        process.stdin.on("end", () => {
            try {
                const self = JSON.parse(raw).Self || {};
                process.stdout.write((self.DNSName || "").replace(/\.$/, ""));
            } catch {
                // Leave the name empty: the caller reports it
            }
        });
    ')
    [ -n "$name" ] || die "could not read this machine's tailnet name. Is Tailscale connected?"
    echo "https://$name"
}

case "${1:-}" in
    install)
        url="$(public_url)"
        GHOST_URL="$url" bash "$SCRIPT_DIR/ghost-local.sh" install
        cat <<EOF

Staging Ghost is running on port $GHOST_PORT with the URL $url
1. Run 'pnpm staging:tunnel' to publish it with Tailscale Funnel
2. Create the owner account at $url/ghost/, then turn on private mode
3. Settings > Advanced > Integrations > Add custom integration, copy the Admin API key
4. In the GitHub 'staging' environment, set GHOST_STAGING_URL=$url
   and the secret GHOST_STAGING_ADMIN_API_KEY
EOF
        ;;
    start | stop | restart | logs)
        bash "$SCRIPT_DIR/ghost-local.sh" "$1"
        ;;
    tunnel)
        tailscale_cli funnel --bg "$GHOST_PORT"
        echo "Staging is published at $(public_url)"
        ;;
    tunnel-off)
        tailscale_cli funnel --https=443 off
        ;;
    url)
        public_url
        ;;
    *)
        echo "Usage: $0 <install|start|stop|restart|logs|tunnel|tunnel-off|url>" >&2
        exit 64
        ;;
esac
