# CloudCannon Jekyll plugin

A Jekyll plugin to create CloudCannon editor details.


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
bundle exec rake test
```

Test multiple Jekyll versions with Appraisal:

```
bundle exec appraisal install
bundle exec appraisal rake test
bundle exec appraisal jekyll-2 rake test
bundle exec appraisal jekyll-4 rake test
```
