# frozen_string_literal: true

require_relative '../logger'
require_relative 'paths'

module CloudCannonJekyll
  # Generator functions for site data
  class Data
    def initialize(site, config)
      @site = site
      @config = config
    end

    def generate_data
      data_config = @config['data_config']
      data = case data_config
             when true
               @site.data&.dup
             when Hash
               @site.data&.select { |key, _| data_config.key?(key) && data_config[key] }
             end

      data ||= {}
      data['categories'] ||= @site.categories.keys
      data['tags'] ||= @site.tags.keys

      data.each_key do |key|
        Logger.info "💾 Processed #{key.bold} data set"
      end

      data
    end
  end
end
