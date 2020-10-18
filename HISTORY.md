# 1.5.0

* Added drafts to collections in details
* Added drafts and data to collections in config
* Added `_path` field to each collection definition in config
* Removed some unused fields
* Renamed `static` to `static-pages` in details and removed `robots.txt` and `sitemap.xml` exceptions

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
