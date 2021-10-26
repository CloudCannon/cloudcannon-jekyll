# frozen_string_literal: true

require_relative '../logger'
require_relative 'paths'

module CloudCannonJekyll
  # Generator functions for site data
  class Data
    def initialize(site)
      @site = site
      @config = site.config
    end

    def generate_data
      cc_data = @config.dig('cloudcannon', 'data')
      data = case cc_data
             when true
               @site.data&.dup
             when Hash
               @site.data&.select { |key, _| cc_data.key?(key) }
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
