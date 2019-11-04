# frozen_string_literal: true

require "jekyll"
require "fileutils"

module CloudCannonJekyll
  class Generator < Jekyll::Generator
    priority :lowest

    def generate(site)
      @site = site
      FileUtils.mkdir_p(File.dirname(destination_path))
      File.open(destination_path, "w") { |f| f.write(file_content) }
      @site.keep_files ||= []
      @site.keep_files << "_cloudcannon/details.json"
    end

    def source_path
      path = "_cloudcannon/details.json"
      path = "_cloudcannon/details-2.x.json" if Jekyll::VERSION.start_with? "2."
      path = "_cloudcannon/details-3.0.x.json" if Jekyll::VERSION.start_with? "3.0."

      File.expand_path(path, File.dirname(__FILE__))
    end

    def destination_path
      Jekyll.sanitized_path(@site.dest, "_cloudcannon/details.json")
    end

    def file_content
      json = PageWithoutAFile.new(@site, File.dirname(__FILE__), "", "_cloudcannon/details.json")
      json.content = File.read(source_path)

      json.data["layout"] = nil
      json.data["sitemap"] = false
      json.data["permalink"] = "/_cloudcannon/details.json"

      json.render({}, @site.site_payload)
      json.output
    end
  end
end
