# frozen_string_literal: true

require 'jekyll'

module CloudCannonJekyll
  # Helper functions for generating paths
  module Paths
    def self.collections_dir(site)
      return '' if Jekyll::VERSION.start_with? '2.'

      site.config['collections_dir']&.sub(%r{^/+}, '') || ''
    end

    def self.data_dir(site)
      site.config['data_dir']&.sub(%r{^/+}, '') || '_data'
    end
  end
end
