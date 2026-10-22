# Casper

A classic theme for [Ghost](http://github.com/tryghost/ghost/), originally the default theme. These days, our default theme is [Source](http://github.com/tryghost/source/)

This is the latest development version of Casper! If you're just looking to download the latest release, head over to the [releases](https://github.com/TryGhost/Casper/releases) page.

&nbsp;

![screenshot-desktop](https://user-images.githubusercontent.com/1418797/183329195-8e8f2ee5-a473-4694-a813-a2575491209e.png)

&nbsp;

# First time using a Ghost theme?

Ghost uses a simple templating language called [Handlebars](http://handlebarsjs.com/) for its themes.

This theme has lots of code comments to help explain what's going on just by reading the code. Once you feel comfortable with how everything works, we also have full [theme API documentation](https://ghost.org/docs/themes/) which explains every possible Handlebars helper and template.

**The main files are:**

- `default.hbs` - The parent template file, which includes your global header/footer
- `index.hbs` - The main template to generate a list of posts, usually the home page
- `post.hbs` - The template used to render individual posts
- `page.hbs` - Used for individual pages
- `tag.hbs` - Used for tag archives, eg. "all posts tagged with `news`"
- `author.hbs` - Used for author archives, eg. "all posts written by Jamie"

One neat trick is that you can also create custom one-off templates by adding the slug of a page to a template file. For example:

- `page-about.hbs` - Custom template for an `/about/` page
- `tag-news.hbs` - Custom template for `/tag/news/` archive
- `author-ali.hbs` - Custom template for `/author/ali/` archive


# Development

Casper styles are compiled using Gulp/PostCSS to polyfill future CSS spec. You'll need [Node](https://nodejs.org/), [pnpm](https://pnpm.io/) and [Gulp](https://gulpjs.com) installed globally. After that, from the theme's root directory:

```bash
# install dependencies
pnpm install

# run development server
pnpm dev
```

Now you can edit `/assets/css/` files, which will be compiled to `/assets/built/` automatically.

The `zip` Gulp task packages the theme files into `dist/<theme-name>.zip`, which you can then upload to your site.

```bash
# create .zip file
pnpm zip
```

# Local development with Ghost

A local Ghost install lives outside this repository (`~/ghost-local` by default) and serves the theme straight from your working tree through a symlink, so there is no zip to rebuild. It needs macOS or Linux, Node 22 (see `.nvmrc`, Ghost itself requires 22.23.1 or later) and pnpm.

```bash
pnpm install
pnpm ghost:install   # once: installs the latest Ghost in development mode and links this theme
pnpm dev             # keep running: rebuilds assets/built/ on change
```

Open http://localhost:2368/ghost/, create the owner account, then activate the `michelin-dev` theme (Design & branding → Change theme). Template and asset changes show up on page reload. Run `pnpm ghost:restart` after editing the theme `config` in `package.json`.

Other commands: `pnpm ghost:start`, `ghost:stop`, `ghost:restart`, `ghost:logs` and `ghost:link` (re-creates the symlink). `GHOST_DIR`, `GHOST_PORT` and `GHOST_VERSION` override the defaults.

# Staging previews

Pull requests can be previewed on a shared Ghost staging site, one at a time:

1. Open a pull request from a branch of this repository (forks are never deployed).
2. Add the `staging` label. The Staging workflow runs `pnpm test:ci`, then uploads the theme to staging. The staging URL is shown in the workflow run summary and on the pull request ("View deployment").
3. Remove the label or close the pull request when you are done: `main` is redeployed.

If another open pull request already carries the label, the deploy fails and names it.

One-time setup:

1. Create a Ghost site dedicated to staging, separate from production. Enabling private mode on it keeps previews behind a password.
2. In its admin, Settings → Advanced → Integrations → Add custom integration, and copy the Admin API key.
3. In GitHub, Settings → Environments → New environment named `staging`, with:
   - the secret `GHOST_STAGING_ADMIN_API_KEY`
   - the variable `GHOST_STAGING_URL`, e.g. `https://staging.example.com`
   - the variable `GHOST_STAGING_ADMIN_URL`, only if the admin lives on another domain
   - optionally, required reviewers to approve each deploy
4. Create the `staging` label.
5. After the first deploy, activate the `michelin` theme once in the staging admin. Later uploads replace it and keep it active.

# Publishing a release

Releases are shipped in two steps. First bump the version — this updates `package.json` and creates the matching commit and `v<version>` git tag:

```bash
# pick one of: patch | minor | major (or an explicit version, e.g. 5.13.0)
pnpm version minor
```

Then run `ship`, which checks the working tree is clean, pushes the commit and tag, and drafts the GitHub release from the changelog:

```bash
pnpm ship
```

> [!NOTE]
> `pnpm version` must be run first — unlike the old `yarn version`, `pnpm version` is not interactive and `pnpm ship` no longer performs the bump itself.

# PostCSS Features Used

- Autoprefixer - Don't worry about writing browser prefixes of any kind, it's all done automatically with support for the latest 2 major versions of every browser.
- [Color Mod](https://github.com/jonathantneal/postcss-color-mod-function)


# SVG Icons

Casper uses inline SVG icons, included via Handlebars partials. You can find all icons inside `/partials/icons`. To use an icon just include the name of the relevant file, eg. To include the SVG icon in `/partials/icons/rss.hbs` - use `{{> "icons/rss"}}`.

You can add your own SVG icons in the same manner.

# Translations

Please see [@TryGhost/Themes/theme-translations/README.md](https://github.com/TryGhost/Themes/blob/main/packages/theme-translations/README.md) for how to build, edit, or contribute translations.

# Copyright & License

Copyright (c) 2013-2026 Ghost Foundation - Released under the [MIT license](LICENSE).
