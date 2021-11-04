# frozen_string_literal: true

require 'jekyll'
require 'fileutils'
require_relative 'logger'
require_relative 'config'
require_relative 'generators/info'

module CloudCannonJekyll
  # Generates JSON file with build information
  class Generator < Jekyll::Generator
    priority :lowest

    # Override the Jekyll::Plugin spaceship to run at the end
    def self.<=>(*)
      1
    end

    def generate(site)
      Logger.info "⭐️ Starting #{'cloudcannon-jekyll'.blue}"
      @site = site
      config = Config.new(site)
      generate_file('info', Info.new.generate_info(site, config.read))
    end

    def generate_file(filename, data)
      dest = destination_path(filename)
      FileUtils.mkdir_p(File.dirname(dest))
      File.open(dest, 'w') { |file| file.write(file_content(data)) }
      @site.keep_files ||= []
      @site.keep_files << path(filename)
      Logger.info "🏁 Generated #{path(filename).bold} #{'successfully'.green}"
    end

    def path(filename)
      "_cloudcannon/#{filename}.json"
    end

    def source_path(filename)
      file_path = path(filename)
      File.expand_path(file_path, File.dirname(__FILE__))
    end

    def destination_path(filename)
      Jekyll.sanitized_path(@site.dest, path(filename))
    end

    def file_content(data)
      JSON.pretty_generate(data)
    end
  end
end
