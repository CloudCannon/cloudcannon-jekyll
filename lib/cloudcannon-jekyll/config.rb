# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require_relative 'logger'

module CloudCannonJekyll
  # Processes Jekyll configuration to enable the plugin and fix common issues
  class Config
    def initialize(site)
      @site_config = site.config
    end

    def read
      config_defaults(config || legacy_config)
    end

    def config
      loaded = config_file('cloudcannon.config.yml') ||
               config_file('cloudcannon.config.yaml')

      Logger.info("⚙️ No config file found at #{'cloudcannon.config.yml'.bold}") unless loaded
      loaded
    end

    def config_file(path)
      loaded = YAML.safe_load(File.read(path))
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
        'collections_config' => @site_config.dig('cloudcannon', 'collections'),
        '_collection_groups' => @site_config['_collection_groups'] || legacy_collection_groups,
        '_select_data' => @site_config['_select_data'] || legacy_select_data,
        '_inputs' => @site_config['_inputs'],
        '_editables' => @site_config['_editables'],
        '_structures' => @site_config['_structures'] || @site_config['_array_structures'],
        '_editor' => @site_config['_editor'],
        '_source_editor' => @site_config['_source_editor'],
        'paths' => {
          'uploads' => @site_config['uploads_dir']
        },

        # Deprecated keys
        '_comments' => @site_config['_comments'],
        '_enabled_editors' => @site_config['_enabled_editors'],
        '_instance_values' => @site_config['_instance_values'],
        '_options' => @site_config['_options']
      }
    end

    def legacy_collection_groups
      @site_config.dig('_explore', 'groups')
    end

    def legacy_select_data
      cloudcannon_keys = %w[_comments _options _editor _explore cloudcannon _collection_groups
                            _enabled_editors _instance_values _source_editor _array_structures
                            uploads_dir _editables _inputs _structures]

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

      select_data.compact
    end
  end
end
