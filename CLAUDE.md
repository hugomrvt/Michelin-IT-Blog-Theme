# Michelin IT Blog theme

Ghost theme forked from Casper. Handlebars templates live at the root and in `partials/`. Sources in `assets/css/` and `assets/js/` are compiled by Gulp into `assets/built/`, which is git-ignored and required by `default.hbs`.

## Commands

pnpm only (version pinned by `packageManager`), Node 22.

- `pnpm install --frozen-lockfile`: install dependencies
- `pnpm dev`: build, then rebuild `assets/built/` on change
- `pnpm test:ci`: build, zip and run gscan with fatal errors. Run it before every push.
- `pnpm zip`: package `dist/michelin.zip`

Local Ghost, installed outside the repo in `~/ghost-local` (override with `GHOST_DIR`):

- `pnpm ghost:install`: first install (latest Ghost, development mode, SQLite), links this repo as the `michelin-dev` theme
- `pnpm ghost:start`, `ghost:stop`, `ghost:restart`, `ghost:logs`
- `pnpm ghost:link`: re-create the symlink and restart Ghost
- Site on http://localhost:2368, admin on `/ghost/`. `.hbs` and `assets/built/` changes show on reload. Restart only after editing `config` in `package.json`.

## Staging

`.github/workflows/staging.yml` deploys one pull request at a time to the shared staging site. A PR from a branch of this repo is deployed when it carries the `staging` label. A second labeled PR makes the deploy fail. Removing the label or closing the PR redeploys `main`. The staging URL is in the workflow run summary. Setup steps are in the README.

The staging site is a second Ghost on the maintainer's Mac (`~/ghost-staging`, port 2369), published with Tailscale Funnel:

- `pnpm staging:install`, `staging:start`, `staging:stop`, `staging:restart`, `staging:logs`
- `pnpm staging:tunnel` / `staging:tunnel-off`: publish or unpublish it, `pnpm staging:url` prints the address
- It never links the working tree. Themes only reach it through the workflow's upload.

## Rules

- Never touch production. No production URL, key or deploy step belongs in this repo.
- The Ghost Admin API key only lives in the `staging` GitHub environment.
- Never commit secrets, `.env` files, Ghost databases, content exports, `assets/built/` or `dist/`.
- Keep dev-only files out of the theme zip (`zipper` in `gulpfile.js`).
- Ask before pushing a branch, opening a PR, adding the `staging` label, publishing the tunnel or provisioning a paid service. Never enable auto-merge.
