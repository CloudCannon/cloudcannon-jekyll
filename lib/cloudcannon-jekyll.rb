# frozen_string_literal: true

require "jekyll"

module CloudCannonJekyll
  autoload :PageWithoutAFile,  "cloudcannon-jekyll/page-without-a-file"
  autoload :Generator,         "cloudcannon-jekyll/generator"
  autoload :Configuration,     "cloudcannon-jekyll/configuration"
  autoload :SafeJsonifyFilter, "cloudcannon-jekyll/safe-jsonify-filter"
  autoload :VERSION,           "cloudcannon-jekyll/version"
end

Liquid::Template.register_filter(CloudCannonJekyll::SafeJsonifyFilter)

# Hooks didn't exist in Jekyll 2 so we monkey patch to get an :after_reset hook
if Jekyll::VERSION.start_with? "2"
  module Jekyll
    class Site
      alias jekyll_reset reset

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