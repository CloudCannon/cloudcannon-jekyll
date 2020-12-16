# 0.3.4

* Re-add id field for documents
* Fix for potential nil reference

# 0.3.3

* Rework fallback for older versions of Jekyll when reading data, posts and drafts again

# 0.3.2

* Rework fallback for older versions of Jekyll when reading data, posts and drafts
* Fix deprecation warning for `posts.map`

# 0.3.1

* Fix for empty collection configurations
* Added max depth parameter for jsonify filter and increase it for array structures in config output

# 0.3.0

* Add empty paths.pages
* Added drafts to collections in details
* Added drafts and data to collections in config
* Added category folder drafts and posts to collections in config
* Added `_path` field to each collection definition in config
* Removed some unused fields
* Renamed static to static-pages in details and removed `robots.txt` and `sitemap.xml` exceptions
* Add `url` to static-pages
* Normalise `_path` in static-pages

# 0.2.2

* Added JSON handling for integers in hash keys
* Fix typo for collections key in older Jekyll versions
* Change date format to ISO8601
* Validate against new version of config schema

# 0.2.1

* Add gem information and time to output config file
* Fix missing in-place compact
* Fix source being output as full path on disk
* Read content for output config file directly from site config

# 0.2.0

* Add defaults and input-options keys to config output
* Add more ignore keys for legacy select data filter
* Reduce methods added from other plugins clashing
* Fix invalid output when unsupported class found

# 0.1.0

* Add output config file
* Add support for including only specified `data` keys
* Fix invalid JSON issue for sites built with Jekyll 2 and no collections
* Change module load style for easier dropping into _plugins

# 0.0.8

* Removed unsupported Jekyll test targets

# 0.0.7

* Fix invalid JSON issue for sites built with Jekyll 2 and no collections

# 0.0.6

* Fixed unsupported Fixnum for Ruby 2.3
* Fixed reference to unsupported String::match? for Ruby 2.3

# 0.0.5

* Support for Ruby 2.3

# 0.0.1 -> 0.0.4

* Initial testing versions
