# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require_relative 'logger'

module CloudCannonJekyll
  MAPPINGS = {
    '_sort_key' => 'sort_key',
    '_subtext_key' => 'subtext_key',
    '_image_key' => 'image_key',
    '_image_size' => 'image_size',
    '_singular_name' => 'singular_name',
    '_singular_key' => 'singular_key',
    '_disable_add' => 'disable_add',
    '_icon' => 'icon',
    '_add_options' => 'add_options'
  }.freeze

  # Processes Jekyll configuration to enable the plugin and fix common issues
  class Config
    def self.rename_legacy_collection_config_keys(collection_config)
      collection_config&.keys&.each do |k|
        collection_config[MAPPINGS[k]] = collection_config.delete(k) if MAPPINGS[k]
      end
    end

    def initialize(site)
      @site_config = site.config
    end

    def read
      config_defaults(custom_config || config || legacy_config)
    end

    def custom_config
      custom_path = ENV['CLOUDCANNON_CONFIG_PATH']
      return unless custom_path

      loaded = config_file(custom_path)
      Logger.info("⚙️ No config file found at #{custom_path.bold}") unless loaded
      loaded
    end

    def config
      loaded = config_file('cloudcannon.config.json') ||
               config_file('cloudcannon.config.yaml') ||
               config_file('cloudcannon.config.yml')

      unless loaded
        Logger.info("⚙️ No config file found at #{'cloudcannon.config.(json|yaml|yml)'.bold}")
      end

      loaded
    end

    def config_file(path)
      loaded = YAML.safe_load(File.read(path)) # Also works for JSON
      Logger.info "⚙️ Using config file at #{path.bold}"
      loaded
    rescue Errno::ENOENT
      nil
    end

    def config_defaults(config)
      defaults = {
        'source' => @site_config['source'].gsub(Dir.pwd, ''),
        'timezone' => @site_config['timezone'],
        'base_url' => @site_config['baseurl']
      }

      defaults.merge(config)
    end

    def legacy_config
      Logger.info('⚙️ Falling back to site config'.yellow)

      {
        'data_config' => @site_config.dig('cloudcannon', 'data'),
        'collections_config' => legacy_collections_config,
        'collection_groups' => @site_config['_collection_groups'] || legacy_collection_groups,
        'editor' => @site_config['_editor'],
        'source_editor' => @site_config['_source_editor'],
        'paths' => {
          'uploads' => @site_config['uploads_dir']
        },
        '_select_data' => @site_config['_select_data'] || legacy_select_data,
        '_inputs' => @site_config['_inputs'],
        '_editables' => @site_config['_editables'],
        '_structures' => @site_config['_structures'],

        # Deprecated keys
        '_array_structures' => @site_config['_array_structures'],
        '_comments' => @site_config['_comments'],
        '_enabled_editors' => @site_config['_enabled_editors'],
        '_instance_values' => @site_config['_instance_values'],
        '_options' => @site_config['_options']
      }
    end

    def legacy_collections_config
      collections_config = @site_config.dig('cloudcannon', 'collections')

      return unless collections_config

      collections_config.each do |_, collection_config|
        Config.rename_legacy_collection_config_keys(collection_config)
      end

      collections_config
    end

    def legacy_collection_groups
      @site_config.dig('_explore', 'groups')
    end

    def legacy_select_data
      cloudcannon_keys = %w[_comments _options _editor _explore cloudcannon _collection_groups
                            _enabled_editors _instance_values _source_editor _array_structures
                            uploads_dir _editables _inputs _structures editor source_editor
                            collection_groups]

      jekyll_keys = %w[source destination collections_dir cache_dir plugins_dir layouts_dir
                       data_dir includes_dir collections safe include exclude keep_files encoding
                       markdown_ext strict_front_matter show_drafts limit_posts future unpublished
                       whitelist plugins markdown highlighter lsi excerpt_separator incremental
                       detach port host baseurl show_dir_listing permalink paginate_path timezone
                       quiet verbose defaults liquid kramdown title url description maruku
                       redcloth rdiscount redcarpet gems plugins]

      keys = cloudcannon_keys + jekyll_keys

      select_data = @site_config.keys.each_with_object({}) do |key, memo|
        value = @site_config[key]

        next unless value.is_a?(Array) || value.is_a?(Hash)
        next if key.nil? || keys.include?(key)

        memo[key] = value
      end

      compacted = select_data.compact
      compacted.empty? ? nil : compacted
    end
  end
end
