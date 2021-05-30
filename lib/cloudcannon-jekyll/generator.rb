# frozen_string_literal: true

require "jekyll"
require "fileutils"
require_relative "reader"

module CloudCannonJekyll
  # Generates JSON files containing build config and build output details
  class Generator < Jekyll::Generator
    # Override the Jekyll::Plugin spaceship to push our plugin to the very end
    priority :lowest
    def self.<=>(*)
      1
    end

    def generate(site)
      @site = site
      @reader = Reader.new(@site)

      collections_config = process_collections_config

      payload = @site.site_payload.merge({
        "gem_version" => CloudCannonJekyll::VERSION,
      })

      drafts = add_blogging_config(collections_config)
      add_collection_paths(collections_config)
      add_data_config(collections_config)
      add_legacy_explore_groups(collections_config)

      generate_file("config", payload.merge({
        "pwd"         => Dir.pwd,
        "config"      => @site.config,
        "collections" => collections_config,
      }))

      generate_file("details", payload.merge({
        "drafts" => drafts,
      }))
    end

    def process_collections_config
      collections = @site.config["collections"]&.dup || {}
      cc_collections = @site.config.dig("cloudcannon", "collections")&.dup || {}

      collections.each_key do |key|
        # Workaround for empty collection configurations
        defaults = collections[key] || { "output" => false }
        cc_collections[key] = (cc_collections[key] || {}).merge(defaults)
      end

      cc_collections
    end

    def collections_dir
      return "" if Jekyll::VERSION.start_with? "2."

      @site.config["collections_dir"] || ""
    end

    def data_dir
      @site.config["data_dir"] || "_data"
    end

    # rubocop:disable Metrics/AbcSize
    def add_category_folder_config(collections_config, posts_config = {})
      posts = @site.posts || @site.collections["posts"]
      docs = posts.class.method_defined?(:docs) ? posts.docs : posts
      seen = {}

      docs.map do |post|
        parts = post.relative_path.split("/_posts/")
        path = parts.first

        # Ignore unless it's an unseen category folder post
        next if parts.length < 2 || path.empty? || seen[path]

        # Could check this to ensure raw files exist since posts can be generated without files
        # next if @reader.read_posts(parts[0]).empty?

        seen[path] = true
        folder = path.sub(%r!^\/+!, "")
        collections_path = "#{collections_dir}/#{folder}".gsub(%r!\/+!, "/").sub(%r!^\/+!, "")

        collections_config["#{folder}/posts"] = posts_config.merge({
          "_path" => "#{collections_path}/_posts",
        })

        # Adding the category draft config like this isn't ideal, since you could have drafts
        #  without posts, but it's a decent trade off vs looking for _drafts folders
        collections_config["#{folder}/drafts"] = posts_config.merge({
          "_path" => "#{collections_path}/_drafts",
        })

        path
      end
    end
    # rubocop:enable Metrics/AbcSize

    # Support for the deprecated _explore configuration
    def add_legacy_explore_groups(collections_config)
      config_groups = @site.config.dig("_explore", "groups")&.dup || []

      groups = config_groups.each_with_object({}) do |group, memo|
        group["collections"].each { |collection| memo[collection] = group["heading"] }
      end

      collections_config.each do |key, collection|
        collection["_group"] ||= groups[key] if groups[key]
      end
    end

    # Add data to collections config if raw data files exist
    def add_data_config(collections_config)
      data_files = @reader.read_data(data_dir)
      collections_config["data"] = { "_path" => data_dir } if data_files&.keys&.any?
    end

    # Add posts/drafts to collections config
    def add_blogging_config(collections_config)
      collections_config["posts"] = { "output" => true } if Jekyll::VERSION.start_with? "2."
      drafts = @reader.read_drafts(collections_dir)

      if drafts.any? || (collections_config.key?("posts") && !collections_config.key?("drafts"))
        collections_config["drafts"] = {}
      end

      folders = add_category_folder_config(collections_config, collections_config["posts"])
      folders.compact.each do |folder|
        drafts += @reader.read_drafts(folder)
      end

      drafts
    end

    # Add _path to each collection config
    def add_collection_paths(collections_config)
      collections_config.each do |key, collection|
        collection["_path"] ||= File.join(collections_dir, "_#{key}").sub(%r!^\/+!, "")
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
