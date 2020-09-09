# frozen_string_literal: true

require "jekyll"
require "fileutils"

module CloudCannonJekyll
  class Generator < Jekyll::Generator
    priority :lowest

    def generate(site)
      @site = site

      payload = @site.site_payload.merge({
        "gem_version" => CloudCannonJekyll::VERSION,
        "pwd"         => Dir.pwd,
        "config"      => @site.config,
      })

      generate_file("details", payload)
      generate_file("config", payload)

      @site.keep_files ||= []
      @site.keep_files << path("details")
      @site.keep_files << path("config")
    end

    def generate_file(filename, data)
      dest = destination_path(filename)
      FileUtils.mkdir_p(File.dirname(dest))
      File.open(dest, "w") { |f| f.write(file_content(filename, data)) }
    end

    def version_path_suffix
      return "-2.x" if Jekyll::VERSION.start_with? "2."
      return "-3.0-4.x" if Jekyll::VERSION.match? %r!3\.[0-4]\.!

      ""
    end

    def path(filename, suffix = "")
      "_cloudcannon/#{filename}#{suffix}.json"
    end

    def source_path(filename)
      File.expand_path(path(filename, version_path_suffix), File.dirname(__FILE__))
    end

    def destination_path(filename)
      Jekyll.sanitized_path(@site.dest, path(filename))
    end

    def file_content(filename, data)
      json = PageWithoutAFile.new(@site, File.dirname(__FILE__), "", path(filename))
      json.content = File.read(source_path(filename))
      json.data["layout"] = nil
      json.data["sitemap"] = false
      json.data["permalink"] = "/#{path(filename)}"
      json.render({}, data)
      json.output
    end
  end
end
