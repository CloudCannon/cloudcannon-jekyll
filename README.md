# CloudCannon Jekyll

A Jekyll plugin that creates [CloudCannon](https://cloudcannon.com/) build information.

This plugin runs during your Jekyll build, discovering your pages, collections, and data files to
create a JSON file used to automatically integrate the site with CloudCannon.

[<img src="https://img.shields.io/gem/v/cloudcannon-jekyll?logo=rubygems" alt="version badge">](https://rubygems.org/gems/cloudcannon-jekyll)
[<img src="https://img.shields.io/gem/dt/cloudcannon-jekyll" alt="downloads badge">](https://rubygems.org/gems/cloudcannon-jekyll)

***

- [Installation](#installation)
- [Configuration](#configuration)
- [Development](#development)
- [License](#license)

***

## Installation

**You don't have to install anything** when building on CloudCannon. This plugin is automatically
installed before your site is built. This gives you the latest support, new features, and fixes
as they are released.

Although **not recommended**, you can install the plugin manually.

<details>
<summary>Manual installation steps</summary>

<blockquote>

When installing manually, you'll have to upgrade when new versions are released.
You could also follow these steps to debug an integration issue locally. This assumes you are using [Bundler](https://bundler.io/) to manage dependencies.

CloudCannon won't automatically install this plugin before builds if `cloudcannon-jekyll` is already installed.

```sh
$ bundle add cloudcannon-jekyll --group jekyll_plugins
```

Add the following to your `_config.yml` if you're listing plugins here as well:

```yaml
plugins:
  - cloudcannon-jekyll
```

💡 For Jekyll versions less than `v3.5.0`, use `gems` instead of `plugins`.

</blockquote>
</details>


## Configuration

This plugin uses an optional configuration file as a base to generate `_cloudcannon/info.json`
(used to integrate your site with CloudCannon).

Add your global CloudCannon configuration to this file, alongside any optional configuration for
this plugin.

Configuration files should be in the same directory you run `bundle exec jekyll build`. The first
supported file found in this order is used:

- `cloudcannon.config.json`
- `cloudcannon.config.yaml`
- `cloudcannon.config.yml`

Alternatively, use the `CLOUDCANNON_CONFIG_PATH` environment variable to use a specific config file
in a custom location:

```sh
$ CLOUDCANNON_CONFIG_PATH=src/cloudcannon.config.yml bundle exec jekyll build
```

Example content for `cloudcannon.config.yml`:

```yaml
# Global CloudCannon configuration
_inputs:
  title:
    type: text
    comment: The title of your page.
_select_data:
  colors:
    - Red
    - Green
    - Blue

# Base path to your site source files, same as source for Jekyll
source: src

# The subpath your built output files are mounted at, same as baseurl for Jekyll
base_url: /documentation

# Populates collections for navigation and metadata in the editor
collections_config:
  people:
    # Base path for files in this collection, relative to source
    path: content/people

    # Whether this collection produces output files or not
    output: true

    # Collection-level configuration
    name: Personnel
    _enabled_editors:
      - data
  posts:
    path: _posts
    output: true
  pages:
    name: Main pages

# Generates the data for select and multiselect inputs matching these names
data_config:
  # Populates data with authors from an data file with the matching name
  authors: true
  offices: true

paths:
  # The default location for newly uploaded files, relative to source
  uploads: assets/uploads

  # The path to the root collections folder, relative to source
  collections: items

  # The path to site data files, relative to source
  data: _data

  # The path to site layout files, relative to source
  layouts: _layouts

  # The path to site include files, relative to source
  includes: _partials
```

See the [CloudCannon documentation](https://cloudcannon.com/documentation/) for more information
on the available features you can configure.

Configuration is set in `cloudcannon.config.*`, but the plugin also automatically
reads and processes the following from Jekyll if unset:

- `collections_config` from `collections` in `_config.yml`
- `paths.collections` from `collections_dir` in `_config.yml`
- `paths.layouts` from `layouts_dir` in `_config.yml`
- `paths.data` from `data_dir` in `_config.yml`
- `paths.includes` from `includes_dir` in `_config.yml`
- `base_url` from `baseurl` in `_config.yml`
- `source` from the `--source` CLI option or `source` in `_config.yml`

## Development

### Releasing new versions

1. Increase the version in `lib/cloudcannon-jekyll/version.rb`
2. Update `HISTORY.md`
3. Commit and push those changes
4. Run `./script/release`
5. [Create a release on GitHub](https://github.com/CloudCannon/cloudcannon-jekyll/releases/new)

### Testing

Running tests for currently installed Jekyll version:

```sh
$ ./script/test
```

Running tests for all specified Jekyll versions:

```sh
$ ./script/test-all-versions
```

Running tests for a specific Jekyll version:

```sh
$ JEKYLL_VERSION="2.4.0" bundle update && ./script/test
```

## License

MIT
