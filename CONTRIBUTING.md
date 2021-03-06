# Contributing to WolcenDB

Talk to Evan before starting your contribution - no guarantee I'll accept it. [A Gitlab issue](https://gitlab.com/erosson/wolcendb/issues/new) is a good place for this.

All contributions are GPL-3.0 licensed, like the rest of WolcenDB

Thank you for your help!

## Build and run the website

See [README.md](README.md)

## Deploying the website

TODO details

Push to Github's master branch. Netlify will detect this and build/deploy automatically. The master branch is always live (unless broken); continuous deployment!

Extracted Wolcen data and images hosted on `img-wolcendb.erosson.org` have a separate release process, described below ('Image hosting').

## Export data from Wolcen

TODO details

directories:

* `datamine.tmp` is everything exported by the WolcenExtractor tool. All Wolcen files. Big, not committed to git.
* `datamine` is everything WolcenDB cares about, copied and transformed from datamine.tmp. xml converted to json. Committed to git, so the website builds/runs on checkout without installing Wolcen.
* `build-img` is exported Wolcen images used on the website.

commands:

* `yarn export:install`: setup WolcenExtractor
* `yarn export`: export everything we possibly can from Wolcen to `datamine.tmp`, mostly using WolcenExtractor. Also runs the steps below.
* `yarn export:datamine`: copy only the Wolcen files we care about from `datamine.tmp` to `datamine`. `datamine` is what's saved to git. Files are only copied, never changed in this step.
* `yarn build:datamine`: converts `datamine` data into JSON-formatted data directly usable by the website, in `build-datamine`. Not saved to git, it's all derived from `datamine`, but this must run before the website will work.

### There is a new version of Wolcen, how do I update the website?

First-time setup steps:

* `yarn export:install` sets up WolcenExtractor, used to extract game data
* `echo $PATH_TO_YOUR_WOLCEN_INSTALL > GAMEPATH`, replacing the path appropriately, so we know where to extract files from

Every-time steps:

* `yarn export` extracts Wolcen files to `datamine` and `/datamine.tmp`. **This will break if you haven't written the `GAMEPATH` file above.**
* If you are NOT authorized to deploy - you probably aren't - send me a pull request with `yarn export`'s changes.
  * Only the `datamine` directory should have changes.
* `yarn start`, and visit `http://localhost:3000/v/__local__`. This runs the website using the data you just exported. Poke around, make sure it looks reasonable.
* If you are authorized to deploy:
  * `yarn build:img`
  * `yarn deploy:img`

Note that the website itself (`wolcendb.erosson.org`) does not need deployment on a Wolcen version change. However, the image data (`img-wolcendb.erosson.org`) does need deployment.

## `yarn export` broke, help

Every once in a while, you should update WolcenExtractor:

* `yarn export:pull` updates WolcenExtractor (it's a git subtree)


## Image hosting

TODO details

Images are hosted separately from the rest of the site, to take advantage of Cloudflare's unlimited bandwidth.

First, install the aws cli. https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html Sorry, this isn't automated (but images don't change often).

* `yarn deploy:img` uploads images to s3. Run `yarn build:img` first

## Terraform

TODO details

Terraform does one-time initial project setup. git repo, static website stuff. If you want to deploy your own instance of wolcendb, change values in deploy.tf to your own stuff, and run `terraform apply`.
