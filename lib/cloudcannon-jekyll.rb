# frozen_string_literal: true

require "jekyll"

require_relative "cloudcannon-jekyll/page-without-a-file"
require_relative "cloudcannon-jekyll/generator"
require_relative "cloudcannon-jekyll/configuration"
require_relative "cloudcannon-jekyll/safe-jsonify-filter"
require_relative "cloudcannon-jekyll/version"

Liquid::Template.register_filter(CloudCannonJekyll::SafeJsonifyFilter)

# Hooks didn't exist in Jekyll 2 so we monkey patch to get an :after_reset hook
if Jekyll::VERSION.start_with? "2"
  module Jekyll
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
