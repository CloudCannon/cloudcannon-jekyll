# frozen_string_literal: true

require "jekyll"

if !Jekyll::VERSION.start_with? "2."
  require_relative "cloudcannon-jekyll/data-reader"
else
  require_relative "cloudcannon-jekyll/old-data-reader"
end

require_relative "cloudcannon-jekyll/page-without-a-file"
require_relative "cloudcannon-jekyll/generator"
require_relative "cloudcannon-jekyll/configuration"
require_relative "cloudcannon-jekyll/jsonify-filter"
require_relative "cloudcannon-jekyll/version"

Liquid::Template.register_filter(CloudCannonJekyll::JsonifyFilter)

if Jekyll::VERSION.start_with? "2."
  module Jekyll
    # Hooks didn't exist in Jekyll 2 so we monkey patch to get an :after_reset hook
    class Site
      alias_method :jekyll_reset, :reset

      def reset
        jekyll_reset
        CloudCannonJekyll::Configuration.set(self)
      end
    end
  end
else
  Jekyll::Hooks.register :site, :after_reset do |site|
    CloudCannonJekyll::Configuration.set(site)
  end
end
