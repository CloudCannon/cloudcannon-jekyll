# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'jekyll'
require 'yaml'
require 'cloudcannon-jekyll'

Jekyll.logger.log_level = :error

SOURCE_DIR = File.expand_path('fixtures', __dir__)
DEST_DIR = File.expand_path('dest', __dir__)

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'

  def source_dir(*files)
    File.join(SOURCE_DIR, *files)
  end

  def dest_dir(*files)
    File.join(DEST_DIR, *files)
  end

  def make_site(options = {}, fixture = 'empty')
    config_defaults = {
      'source' => File.expand_path(fixture, source_dir),
      'destination' => File.expand_path(fixture, dest_dir)
    }.freeze

    site_config = Jekyll.configuration(options.merge(config_defaults))
    Jekyll::Site.new(site_config)
  end
end
