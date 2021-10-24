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
    def generate_info(site)
      @config = site.config
      @data_dir = Paths.data_dir(site)
      @collections_dir = Paths.collections_dir(site)

      migrate_legacy_config

      data_generator = Data.new(site)
      data = data_generator.generate_data

      collections_generator = Collections.new(site)
      collections_config = collections_generator.generate_collections_config
      collections = collections_generator.generate_collections(collections_config)
      collections_generator.remove_empty_collection_config(
        collections_config,
        collections
      )

      info = {
        time: site.time.iso8601,
        version: '0.0.2',
        cloudcannon: generate_cloudcannon,
        generator: generate_generator,
        paths: generate_paths,
        'collections-config' => collections_config,
        collections: collections,
        data: data,
        source: @config['source'].gsub(Dir.pwd, '')
      }

      info['timezone'] = @config['timezone'] if @config['timezone']
      info['base-url'] = @config['baseurl'] if @config['baseurl']
      info['_comments'] = @config['_comments'] if @config['_comments']
      info['_enabled_editors'] = @config['_enabled_editors'] if @config['_enabled_editors']
      info['_instance_values'] = @config['_instance_values'] if @config['_instance_values']
      info['_options'] = @config['_options'] if @config['_options']
      info['_inputs'] = @config['_inputs'] if @config['_inputs']
      info['_editables'] = @config['_editables'] if @config['_editables']
      info['_collection_groups'] = @config['_collection_groups'] if @config['_collection_groups']
      info['_select_data'] = @config['_select_data'] if @config['_select_data']
      info['_array_structures'] = @config['_array_structures'] if @config['_array_structures']
      info['_editor'] = @config['_editor'] if @config['_editor']
      info['_source_editor'] = @config['_source_editor'] if @config['_source_editor']
      info['defaults'] = @config['defaults'] if @config['defaults']
      info
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
        uploads: @config['uploads_dir'],
        data: @data_dir,
        collections: @collections_dir,
        layouts: @config['layouts_dir']
      }
    end

    def generate_generator
      {
        name: 'jekyll',
        version: Jekyll::VERSION,
        environment: Jekyll.env,
        metadata: {
          markdown: @config['markdown'],
          kramdown: @config['kramdown'],
          commonmark: @config['commonmark']
        }
      }
    end

    def migrate_legacy_config
      add_legacy_explore_groups
      add_legacy_select_data
    end

    # Support for the deprecated _explore configuration
    def add_legacy_explore_groups
      return if @config.key?('_collection_groups')

      collection_groups = @config.dig('_explore', 'groups')&.dup
      @config['_collection_groups'] = collection_groups
    end

    def add_legacy_select_data
      return if @config.key?('_select_data')

      cloudcannon_keys = %w[_comments _options _editor _explore cloudcannon
                            _collection_groups _enabled_editors _instance_values
                            _source_editor _array_structures uploads_dir _inputs
                            _structures]

      jekyll_keys = %w[source destination collections_dir cache_dir plugins_dir
                       layouts_dir data_dir includes_dir collections safe
                       include exclude keep_files encoding markdown_ext
                       strict_front_matter show_drafts limit_posts future
                       unpublished whitelist plugins markdown highlighter lsi
                       excerpt_separator incremental detach port host baseurl
                       show_dir_listing permalink paginate_path timezone quiet
                       verbose defaults liquid kramdown title url description
                       maruku redcloth rdiscount redcarpet gems plugins]

      select_data = @config.keys.each_with_object({}) do |key, memo|
        value = @config[key]

        next unless value.is_a?(Array) || value.is_a?(Hash)
        next if key.nil? ||
                cloudcannon_keys.include?(key) ||
                jekyll_keys.include?(key)

        memo[key] = value
      end

      @config['_select_data'] = select_data.compact
    end
  end
end
