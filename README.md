# CloudCannon Jekyll plugin

A Jekyll plugin to create CloudCannon editor details.

[![Build Status](https://travis-ci.com/CloudCannon/cloudcannon-jekyll.svg?branch=main)](https://travis-ci.com/CloudCannon/cloudcannon-jekyll) [![Gem Version](https://badge.fury.io/rb/cloudcannon-jekyll.svg)](https://badge.fury.io/rb/cloudcannon-jekyll)

## Note
This gem is installed as part of the build process on CloudCannon, and should not be added
to any Jekyll sites manually.

## Usage

1. Add `gem 'cloudcannon-jekyll'` to your site's `Gemfile`
2. Run `bundle install`
3. Add the following to your site's `_config.yml`:

```yaml
plugins:
  - cloudcannon-jekyll
```

💡 If you are using a Jekyll version less than 3.5.0, use the gems key instead of plugins.


## Releasing new version

1. Increase version in lib/cloudcannon-jekyll/version.rb
2. Update HISTORY.md
3. Create a release and tag in GitHub
4. Build new gem with `gem build cloudcannon-jekyll.gemspec`
5. Push new version to rubygems.org with `gem push cloudcannon-jekyll-{{ VERSION HERE }}.gem`


## Testing

```
bundle exec rspec
```

To test a specific Jekyll version:

```
JEKYLL_VERSION="2.4.0" bundle update && bundle exec rspec
```
