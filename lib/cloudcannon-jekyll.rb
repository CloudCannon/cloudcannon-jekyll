# frozen_string_literal: true

require 'jekyll'
require_relative 'cloudcannon-jekyll/generator'
require_relative 'cloudcannon-jekyll/setup'
require_relative 'cloudcannon-jekyll/version'

if Jekyll::VERSION.start_with? '2.'
  module Jekyll
    # Hooks didn't exist in Jekyll 2 so we monkey patch to get an :after_reset hook
    class Site
      alias jekyll_reset reset

      def reset
        jekyll_reset
        CloudCannonJekyll::Setup.set(self)
      end
    end
  end
else
  Jekyll::Hooks.register :site, :after_reset do |site|
    CloudCannonJekyll::Setup.set(site)
  end
end
