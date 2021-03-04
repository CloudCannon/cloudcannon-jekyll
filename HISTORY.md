# 1.6.1

* Increase max depth for array structures defined outside of global

# 1.6.0

* Add `collections_dir` to details collection item paths

# 1.5.7

* Fix pages collection clash with built-in pages
* Fixed posts collection config data overwriting drafts data

# 1.5.6

* Force generator to run after other lowest priority plugins

# 1.5.5

* Re-add id field for documents
* Fix for potential nil reference

# 1.5.4

* Rework fallback for older versions of Jekyll when reading data, posts and drafts again

# 1.5.3

* Rework fallback for older versions of Jekyll when reading data, posts and drafts
* Fix deprecation warning for `posts.map`

# 1.5.2

* Fix for empty collection configurations

# 1.5.1

* Add empty paths.pages

# 1.5.0

* Added drafts to collections in details
* Added drafts and data to collections in config
* Added category folder drafts and posts to collections in config
* Added `_path` field to each collection definition in config
* Removed some unused fields
* Renamed static to static-pages in details and removed `robots.txt` and `sitemap.xml` exceptions
* Add `url` to static-pages
* Normalise `_path` in static-pages

# 1.4.3

* Fix off-by-one depth for nested documents from last change

# 1.4.2

* Added max depth parameter for jsonify filter and increase it for array structures in config output

# 1.4.1

* Added JSON handling for integers in hash keys

# 1.4.0

* Fix typo for collections key in older Jekyll versions
* Change date format to ISO8601
* Validate against new version of config schema

# 1.3.3

* Add gem information and time to output config file

# 1.3.2

* Fix missing in-place compact

# 1.3.1

* Fix source being output as full path on disk
* Read content for output config file directly from site config

# 1.3.0

* Add defaults and input-options keys to config output

# 1.2.3

* Add more ignore keys for legacy select data filter

# 1.2.2

* Reduce methods added from other plugins clashing

# 1.2.1

* Fix invalid output when unsupported class found

# 1.2.0

* Add output config file

# 1.1.0

* Add support for including only specified `data` keys

# 1.0.3

* Fix invalid JSON issue for sites built with Jekyll 2 and no collections

# 1.0.2

* Change module load style for easier dropping into _plugins

# 1.0.1

* Set required Ruby version

# 1.0.0

* Initial release
* Dropped support for ruby 2.3

# 0.0.5

* Support for Ruby 2.3

# 0.0.1 -> 0.0.4

* Initial testing versions
