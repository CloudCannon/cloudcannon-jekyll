# frozen_string_literal: true

require "cloudcannon-jekyll/generator"
require "cloudcannon-jekyll/safe-jsonify-filter"

module CloudCannonJekyll
  autoload :PageWithoutAFile, "cloudcannon-jekyll/page-without-a-file.rb"

  Liquid::Template.register_filter(SafeJsonifyFilter)
end
