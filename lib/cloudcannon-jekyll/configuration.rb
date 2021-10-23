# frozen_string_literal: true

module CloudCannonJekyll
  # Processes Jekyll configuration to enable the plugin and fix common issues
  class Configuration
    def self.processed?(site)
      site.instance_variable_get(:@_cloudcannon_jekyll_processed) == true
    end

    def self.process(site)
      site.instance_variable_set :@_cloudcannon_jekyll_processed, true
    end

    def self.overridden_config(user_config)
      config = Jekyll::Utils.deep_merge_hashes(
        Jekyll::Configuration::DEFAULTS,
        user_config
      )

      if config.respond_to? :add_default_collections
        config = config.add_default_collections
      end

      config = config.fix_common_issues if config.respond_to? :fix_common_issues

      if config.respond_to? :add_default_excludes
        config = config.add_default_excludes
      end

      key = Jekyll::VERSION.start_with?('2.') ? 'gems' : 'plugins'

      config[key] = Array(config[key])

      unless config[key].include? 'cloudcannon-jekyll'
        config[key].push('cloudcannon-jekyll')
      end

      config
    end

    def self.set(site)
      return if processed? site

      if site.respond_to? :config=
        site.config = overridden_config(site.config)
      else # Jekyll pre 3.5
        site.instance_variable_set :@config, overridden_config(site.config)
      end

      process(site)
    end
  end
end
