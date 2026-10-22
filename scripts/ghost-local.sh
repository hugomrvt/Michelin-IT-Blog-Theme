#!/usr/bin/env bash
#
# Manage a local Ghost install that lives OUTSIDE this repository and serves
# the theme straight from the working tree through a symlink, so there is no
# zip to rebuild while developing.
#
# Usage: scripts/ghost-local.sh <install|link|start|stop|restart|logs>
#
# Environment overrides:
#   GHOST_DIR        Ghost install directory      (default: ~/ghost-local)
#   GHOST_PORT       Port Ghost listens on         (default: 2368)
#   GHOST_VERSION    Ghost version to install      (default: latest)
#   GHOST_URL        Public URL configured in Ghost (default: http://localhost:$GHOST_PORT)
#   GHOST_LINK_THEME 0 to skip linking the working tree (default: 1)
#   THEME_LINK_NAME  Theme folder name inside Ghost (default: michelin-dev)
#
# The theme is linked as "michelin-dev" rather than "michelin" so that
# uploading a michelin.zip through the local admin can never land on the
# symlink and overwrite this working tree.
#
# scripts/ghost-staging.sh reuses this script for the staging instance.

set -euo pipefail

GHOST_CLI_VERSION="1.34.0"
GHOST_DIR="${GHOST_DIR:-$HOME/ghost-local}"
GHOST_PORT="${GHOST_PORT:-2368}"
GHOST_VERSION="${GHOST_VERSION:-}"
GHOST_URL="${GHOST_URL:-http://localhost:$GHOST_PORT}"
GHOST_LINK_THEME="${GHOST_LINK_THEME:-1}"
GHOST_PNAME="${GHOST_PNAME:-ghost-local}"
GHOST_INSTALL_CMD="${GHOST_INSTALL_CMD:-pnpm ghost:install}"
THEME_LINK_NAME="${THEME_LINK_NAME:-michelin-dev}"
THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

ghost() {
    npx --yes "ghost-cli@${GHOST_CLI_VERSION}" "$@" --dir "$GHOST_DIR"
}

die() {
    echo "ghost-local: $*" >&2
    exit 1
}

require_install() {
    [ -f "$GHOST_DIR/.ghost-cli" ] || die "no Ghost install in $GHOST_DIR. Run '$GHOST_INSTALL_CMD' first."
}

case "$GHOST_DIR/" in
    "$THEME_DIR"/*) die "GHOST_DIR must live outside the theme repository ($THEME_DIR)." ;;
esac

link_theme() {
    local target="$GHOST_DIR/content/themes/$THEME_LINK_NAME"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        die "$target exists and is not a symlink, refusing to replace it."
    fi

    # Ghost serves assets/built/, which is git-ignored: build it once if missing
    if [ ! -f "$THEME_DIR/assets/built/screen.css" ]; then
        (cd "$THEME_DIR" && pnpm build)
    fi

    ln -sfn "$THEME_DIR" "$target"
    echo "Linked $target -> $THEME_DIR"
}

cmd_install() {
    if [ -e "$GHOST_DIR" ] && [ -n "$(ls -A "$GHOST_DIR" 2>/dev/null)" ]; then
        die "$GHOST_DIR already exists and is not empty."
    fi
    mkdir -p "$GHOST_DIR"

    ghost install ${GHOST_VERSION:+"$GHOST_VERSION"} --local \
        --port "$GHOST_PORT" --url "$GHOST_URL" --pname "$GHOST_PNAME" \
        --no-start --no-prompt

    if [ "$GHOST_LINK_THEME" = 0 ]; then
        ghost start
        return
    fi

    link_theme
    ghost start

    cat <<EOF

Ghost is running at http://localhost:$GHOST_PORT
1. Create the owner account at http://localhost:$GHOST_PORT/ghost/
2. Settings > Design & branding > Change theme > activate "$THEME_LINK_NAME"
3. Run 'pnpm dev' in this repository to rebuild assets on change
EOF
}

case "${1:-}" in
    install)
        cmd_install
        ;;
    link)
        require_install
        link_theme
        # Ghost only discovers new theme folders on boot
        ghost restart
        ;;
    start | stop | restart)
        require_install
        ghost "$1"
        ;;
    logs)
        require_install
        ghost log --follow
        ;;
    *)
        echo "Usage: $0 <install|link|start|stop|restart|logs>" >&2
        exit 64
        ;;
esac
