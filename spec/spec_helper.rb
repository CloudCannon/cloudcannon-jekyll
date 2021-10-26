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

  def log_schema_error(error)
    # Expecting here rather than logging means it get output in the test results
    log = "'#{error['data_pointer']}' schema mismatch: (data: #{error['data']})"\
      " (schema: #{error['schema']})"
    expect(log).to be_nil
  end

  def source_dir(*files)
    File.join(SOURCE_DIR, *files)
  end

  def dest_dir(*files)
    File.join(DEST_DIR, *files)
  end

  def make_site(options = {}, fixture = 'standard')
    config_defaults = {
      'source' => File.expand_path(fixture, source_dir),
      'destination' => dest_dir
    }.freeze

    site_config = Jekyll.configuration(config_defaults.merge(options))
    Jekyll::Site.new(site_config)
  end
end
