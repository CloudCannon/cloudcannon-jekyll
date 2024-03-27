# frozen_string_literal: true

require 'jekyll'
require 'fileutils'
require_relative '../logger'
require_relative 'collections'
require_relative 'data'
require_relative 'paths'

module CloudCannonJekyll
  # Generates a summary of a Jekyll site
  class Info
    def generate_info(site, config)
      @site = site
      @site_config = site.config
      @config = config
      @data_dir = Paths.data_dir(site)
      @collections_dir = Paths.collections_dir(site)

      collections_generator = Collections.new(site, config)
      collections_config = collections_generator.generate_collections_config
      collections = collections_generator.generate_collections(collections_config)
      collections_generator.remove_empty_collection_config(collections_config, collections)

      base = @config || {}

      generated = {
        time: site.time.iso8601,
        version: '0.0.3',
        cloudcannon: generate_cloudcannon,
        generator: generate_generator,
        paths: generate_paths,
        collections_config: collections_config,
        collections: collections,
        data: generate_data,
        source: @config['source'] || '',
        base_url: @config['base_url'] || '',

        # Jekyll-only
        defaults: @site_config['defaults']
      }

      base.merge(generated).compact
    end

    def generate_data
      data_generator = Data.new(@site, @config)
      data_generator.generate_data
    end

    def generate_cloudcannon
      {
        name: 'cloudcannon-jekyll',
        version: CloudCannonJekyll::VERSION
      }
    end

    def generate_paths
      {
        static: '',
        uploads: @config.dig('paths', 'uploads') || 'uploads',
        uploads_use_relative_path: @config.dig('paths', 'uploads_use_relative_path') || false,
        dam_uploads: @config.dig('paths', 'dam_uploads') || '',
        dam_static: @config.dig('paths', 'dam_static') || '',
        data: @data_dir,
        collections: @collections_dir,
        layouts: @site_config['layouts_dir'] || '_layouts'
      }
    end

    def generate_generator
      {
        name: 'jekyll',
        version: Jekyll::VERSION,
        environment: Jekyll.env,
        metadata: {
          markdown: @site_config['markdown'],
          kramdown: @site_config['kramdown'],
          commonmark: @site_config['commonmark']
        }
      }
    end
  end
end
