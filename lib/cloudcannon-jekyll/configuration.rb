# frozen_string_literal: true

module CloudCannonJekyll
  class Configuration
    class << self
      def processed?(site)
        site.instance_variable_get(:@_cloudcannon_jekyll_processed) == true
      end

      def process(site)
        site.instance_variable_set :@_cloudcannon_jekyll_processed, true
      end

      def overridden_config(user_config)
        config = Jekyll::Utils.deep_merge_hashes(Jekyll::Configuration::DEFAULTS, user_config)
        config = config.add_default_collections if config.respond_to? :add_default_collections
        config = config.fix_common_issues if config.respond_to? :fix_common_issues
        config = config.add_default_excludes if config.respond_to? :add_default_excludes

        if Jekyll::VERSION.start_with? "2"
          config["gems"] = Array(config["gems"])
          config["gems"].push("cloudcannon-jekyll") unless config["gems"].include? "cloudcannon-jekyll"
        else
          config["plugins"] = Array(config["plugins"])
          config["plugins"].push("cloudcannon-jekyll") unless config["plugins"].include? "cloudcannon-jekyll"
        end

        config
      end

      def set(site)
        return if processed? site

        config = overridden_config(site.config)

        if site.respond_to? :config=
          site.config = config
        else # Jekyll pre 3.5
          site.instance_variable_set :@config, config
        end

        process(site)
      end
    end
  end
end
