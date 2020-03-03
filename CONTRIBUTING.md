# Contributing to WolcenDB

Talk to Evan before starting your contribution - no guarantee I'll accept it. [A Gitlab issue](https://gitlab.com/erosson/wolcendb/issues/new) is a good place for this.

All contributions are GPL-3.0 licensed, like the rest of WolcenDB

Thank you for your help!

## Deploying the website

TODO details

Push to Github's master branch. Netlify will detect this and build/deploy automatically. The master branch is always live (unless broken); continuous deployment!

## Export data from Wolcen

TODO details

directories:

* `datamine.tmp` is everything exported by the WolcenExtractor tool. All Wolcen files. Big, not committed to git.
* `datamine` is everything WolcenDB cares about, copied and transformed from datamine.tmp. xml converted to json. Committed to git, so the website builds/runs on checkout without installing Wolcen.
* `public/static` is exported Wolcen images used on the website.

commands:

* `yarn export:install`: setup WolcenExtractor
* `yarn export`
* `yarn export:cp`: copy files from `datamine.tmp` to `datamine`. convert wolcen xml to elm-friendly json. create one js file to import all json, `datamine/imports.js`. import_datamine.js

## Detailed build process

TODO details

Build process is more complex than many Elm apps.

* `yarn build`
* `yarn build:search-index`: generate `datamine/searchIndex.json`, needed for the top-right searchbar. build-search-index-cli.mjs, BuildSearchIndexCLI.elm
* `yarn build:ssr`: server-side rendering. generate loading/non-interactive copies of each page at build-time. creates dir structure in `/build`/`/build-ssr`. if this breaks, 100% safe to skip this; when not used (like in dev) it simply skips the non-interactive preview. ssr-cli.js, SSRPagesCLI.elm, SSRRenderCLI.elm

## Image hosting

TODO details

Images are hosted separately from the rest of the site, to take advantage of Cloudflare's unlimited bandwidth.

First, install the aws cli. https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html Sorry, this isn't automated (but images don't change often).

* `yarn export:images` uploads images to s3. Run `yarn export` and `yarn export:cp` first

## Terraform

TODO details

Terraform does one-time initial project setup. git repo, static website stuff. If you want to deploy your own instance of wolcendb, change values in deploy.tf to your own stuff, and run `terraform apply`.
