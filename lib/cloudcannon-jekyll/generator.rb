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

    # rubocop:disable Metrics/MethodLength
    def generate(site)
      log "⭐️ Starting #{"cloudcannon-jekyll".blue}"

      @site = site
      @reader = Reader.new(@site)

      migrate_legacy_config
      pages = generate_pages
      collections_config = generate_collections_config(pages)
      drafts = add_blogging_config(collections_config)
      add_collection_paths(collections_config)

      collections = generate_collections(collections_config, pages, drafts)
      remove_empty_collection_config(collections_config, collections)

      add_data_config(collections_config)
      data = generate_data

      generate_file("info", @site.site_payload.merge({
        "pwd"                => Dir.pwd,
        "version"            => "0.0.2",
        "gem_version"        => CloudCannonJekyll::VERSION,
        "config"             => @site.config,
        "collections_config" => collections_config,
        "collections"        => collections,
        "data"               => data,
      }))
    end
    # rubocop:enable Metrics/MethodLength

    def generate_collections_config(pages)
      collections = @site.config["collections"]&.dup || {}
      collections_config = @site.config.dig("cloudcannon", "collections")&.dup || {}

      collections.each_key do |key|
        # Workaround for empty collection configurations
        defaults = collections[key] || { "output" => false }
        collections_config[key] = (collections_config[key] || {}).merge(defaults)
      end

      unless pages.empty?
        collections_config["pages"] ||= {
          "output" => true,
          "filter" => "strict",
          "path"   => "",
        }
      end

      collections_config
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def generate_collections(collections_config, pages, drafts)
      split_posts = group_by_category_folder(all_posts, "posts")
      split_drafts = group_by_category_folder(drafts, "drafts")

      collections = {}
      collections_config.each_key do |key|
        collections[key] = if key == "posts" || key.end_with?("/posts")
                             split_posts[key]
                           elsif key == "drafts" || key.end_with?("/drafts")
                             split_drafts[key]
                           else
                             @site.collections[key]&.docs
                           end

        collections[key] ||= []
      end

      collections["pages"] = pages if collections["pages"].empty? && !pages.empty?
      collections
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def generate_data
      cc_data = @site.config.dig("cloudcannon", "data")
      data = if cc_data == true
               @site.data&.dup
             elsif cc_data&.is_a?(Hash)
               @site.data&.select { |key, _| cc_data.key?(key) }
             end

      data ||= {}
      data["categories"] ||= @site.categories.keys
      data["tags"] ||= @site.tags.keys

      data.each_key do |key|
        log "💾 Processed #{key.bold} data set"
      end

      data
    end

    def generate_pages
      html_pages = @site.pages.select do |page|
        page.html? || page.url.end_with?("/")
      end

      static_pages = @site.static_files.select do |static_page|
        JsonifyFilter::STATIC_EXTENSIONS.include?(static_page.extname)
      end

      html_pages + static_pages
    end

    def collections_dir
      return "" if Jekyll::VERSION.start_with? "2."

      @site.config["collections_dir"] || ""
    end

    def data_dir
      @site.config["data_dir"] || "_data"
    end

    def all_posts
      posts = @site.posts || @site.collections["posts"]
      posts.class.method_defined?(:docs) ? posts.docs : posts
    end

    def group_by_category_folder(collection, key)
      split_path = "/_#{key}/"
      collection.group_by do |doc|
        parts = doc.relative_path.split(split_path)
        if parts.length > 1
          "#{parts.first}/#{key}".sub(%r!^\/+!, "")
        else
          key
        end
      end
    end

    def add_category_folder_config(collections_config, posts_config = {})
      seen = {}

      all_posts.map do |post|
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
          "path" => "#{collections_path}/_posts",
        })

        # Adding the category draft config like this isn't ideal, since you could have drafts
        #  without posts, but it's a decent trade off vs looking for _drafts folders
        collections_config["#{folder}/drafts"] = posts_config.merge({
          "path" => "#{collections_path}/_drafts",
        })

        path
      end
    end

    def remove_empty_collection_config(collections_config, collections)
      cc_collections = @site.config.dig("cloudcannon", "collections") || {}

      collections_config.each_key do |key|
        if collections[key].empty? && !cc_collections.key?(key)
          log "📂 #{"Ignored".yellow} #{key.bold} collection with no files or configuration"
          collections_config.delete(key)
        else
          log "📁 Processed #{key.bold} collection with #{collections[key]&.length || 0} files"
        end
      end
    end

    def migrate_legacy_config
      add_legacy_explore_groups
    end

    # Support for the deprecated _explore configuration
    def add_legacy_explore_groups
      unless @site.config.key?("_collection_groups")
        @site.config["_collection_groups"] = @site.config.dig("_explore", "groups")&.dup
      end
    end

    # Add data to collections config if raw data files exist
    def add_data_config(collections_config)
      data_files = @reader.read_data(data_dir)
      collections_config["data"] = { "path" => data_dir } if data_files&.keys&.any?
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

    # Add path to each collection config
    def add_collection_paths(collections_config)
      collections_config.each do |key, collection|
        collection["path"] ||= File.join(collections_dir, "_#{key}").sub(%r!^\/+!, "")
      end
    end

    def generate_file(filename, data)
      dest = destination_path(filename)
      FileUtils.mkdir_p(File.dirname(dest))
      File.open(dest, "w") { |file| file.write(file_content(filename, data)) }
      @site.keep_files ||= []
      @site.keep_files << path(filename)
      log "🏁 Generated #{path(filename).bold} #{"successfully".green}"
    end

    def log(str)
      Jekyll.logger.info("CloudCannon:", str)
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
