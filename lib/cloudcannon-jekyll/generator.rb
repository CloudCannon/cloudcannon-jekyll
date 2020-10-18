# frozen_string_literal: true

require "jekyll"
require "fileutils"

module CloudCannonJekyll
  # Generates JSON files containing build config and build output details
  class Generator < Jekyll::Generator
    priority :lowest

    def generate(site)
      @site = site

      collections_config = @site.config["collections"].dup || {}
      drafts = read_drafts

      payload = @site.site_payload.merge({
        "gem_version" => CloudCannonJekyll::VERSION,
      })

      add_blogging_config(collections_config, drafts)
      add_collection_paths(collections_config)
      add_data_config(collections_config)

      generate_file("config", payload.merge({
        "pwd"         => Dir.pwd,
        "config"      => @site.config,
        "collections" => collections_config,
      }))

      generate_file("details", payload.merge({
        "drafts" => drafts,
      }))
    end

    def collections_dir
      @site.config["collections_dir"] || ""
    end

    def data_dir
      @site.config["data_dir"] || "_data"
    end

    def read_data
      if Jekyll::VERSION.start_with? "2."
        CloudCannonJekyll::OldDataReader.new(@site).read("_data")
      else
        CloudCannonJekyll::DataReader.new(@site).read(data_dir)
      end
    end

    def read_drafts
      if Jekyll::VERSION.start_with? "2."
        @site.read_content("", "_drafts", Jekyll::Draft)
      else
        Jekyll::PostReader.new(@site).read_drafts(collections_dir)
      end
    end

    # Add data to collections config if raw data files exist
    def add_data_config(collections)
      data_files = read_data
      collections["data"] = { "_path" => data_dir } if data_files&.keys&.any?
    end

    # Add posts/drafts to collections config
    def add_blogging_config(collections, drafts)
      collections["posts"] = { "output" => true } if Jekyll::VERSION.start_with? "2."

      if collections.key?("posts")
        collections["drafts"] = collections["posts"].dup
      elsif drafts&.any?
        collections["drafts"] = {}
      end
    end

    # Add _path to each collection config
    def add_collection_paths(collections)
      collections.each do |key, collection|
        collection["_path"] = File.join(collections_dir, "_#{key}").sub(%r!^\/+!, "")
      end
    end

    def generate_file(filename, data)
      dest = destination_path(filename)
      FileUtils.mkdir_p(File.dirname(dest))
      File.open(dest, "w") { |file| file.write(file_content(filename, data)) }
      @site.keep_files ||= []
      @site.keep_files << path(filename)
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
      page = PageWithoutAFile.new(@site, File.dirname(__FILE__), "", path(filename))
      page.content = File.read(source_path(filename))
      page.data["layout"] = nil
      page.data["sitemap"] = false
      page.data["permalink"] = "/#{path(filename)}"
      page.render({}, data)
      page.output
    end
  end
end
