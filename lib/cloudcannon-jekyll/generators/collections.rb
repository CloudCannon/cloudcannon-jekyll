# frozen_string_literal: true

require 'fileutils'
require_relative '../readers/reader'
require_relative '../logger'
require_relative 'paths'

module CloudCannonJekyll
  STATIC_EXTENSIONS = ['.html', '.htm'].freeze
  IS_JEKYLL_2_X_X = Jekyll::VERSION.start_with?('2.').freeze
  IS_JEKYLL_3_04_X = Jekyll::VERSION.match?(/3\.[0-4]\./).freeze

  # Helper functions for generating collection configuration and summaries
  class Collections
    def initialize(site, config)
      @site = site
      @config = config
      @reader = Reader.new(site)
      @collections_dir = Paths.collections_dir(site)
      @data_dir = Paths.data_dir(site)
      @split_posts = group_by_category_folder(all_posts, 'posts')
      @split_drafts = group_by_category_folder(all_drafts, 'drafts')
    end

    def generate_collections_config
      collections = @site.config['collections'] || {}
      collections_config = @config['collections_config']&.dup || {}

      if collections.is_a?(Array)
        collections = collections.each_with_object({}) { |key, memo| memo[key] = {} }
      end

      defaults = {
        'data' => {
          'path' => @data_dir,
          'output' => false
        },
        'posts' => {
          'output' => true
        },
        'drafts' => {
          'output' => !!@site.show_drafts
        }
      }

      unless collections.key?('pages') && !collections['pages'].empty?
        defaults['pages'] = {
          'path' => '',
          'output' => true,
          'filter' => 'strict'
        }
      end

      collection_keys = (defaults.keys + collections.keys).uniq

      collection_keys.each do |key|
        processed = (defaults[key] || {})
                    .merge(collections[key] || {})
                    .merge(collections_config[key] || {})

        processed['output'] ||= false
        processed['auto_discovered'] = !collections_config.key?(key)
        processed['path'] ||= File.join(@collections_dir, "_#{key}")
        processed['path'] = processed['path'].sub(%r{^/+}, '')

        Config.rename_legacy_collection_config_keys(processed)

        collections_config[key] = processed
      end

      @split_posts.each_key do |key|
        posts_path = @split_posts[key]&.first&.relative_path&.sub(%r{(^|/)_posts.*}, '\1_posts')
        next unless posts_path

        defaults = {
          'auto_discovered' => !collections_config.key?(key),
          'path' => File.join(@collections_dir, posts_path).sub(%r{^/+}, ''),
          'output' => true
        }

        collections_config[key] = defaults.merge(collections_config[key] || {})
      end

      @split_drafts.each_key do |key|
        drafts_path = @split_drafts[key]&.first&.relative_path&.sub(%r{(^|/)_drafts.*}, '\1_drafts')
        next unless drafts_path

        defaults = {
          'auto_discovered' => !collections_config.key?(key),
          'path' => File.join(@collections_dir, drafts_path).sub(%r{^/+}, ''),
          'output' => !!@site.show_drafts
        }

        collections_config[key] = defaults.merge(collections_config[key] || {})
      end

      collections_config
    end

    def drafts_paths
      paths = @split_posts.keys.map do |key|
        File.join('/', @collections_dir, key.sub(/posts$/, '_drafts'))
      end

      paths.empty? ? [File.join('/', @collections_dir, '_drafts')] : paths
    end

    def generate_collections(collections_config)
      collections = {}

      collections_config.each_key do |key|
        next if key == 'data'

        collections[key] = if key == 'posts' || key.end_with?('/posts')
                             @split_posts[key]
                           elsif key == 'drafts' || key.end_with?('/drafts')
                             @split_drafts[key]
                           else
                             @site.collections[key]&.docs
                           end

        collections[key] ||= []
        collections[key] = collections[key].map do |doc|
          document_to_json(doc, key)
        end
      end

      if collections['pages'].empty?
        collections['pages'] = all_pages.map do |doc|
          document_to_json(doc, 'pages')
        end
      end

      collections
    end

    def remove_empty_collection_config(collections_config, collections)
      collections_config.each do |key, collection_config|
        should_delete = if key == 'data'
                          !data_files?
                        else
                          collections[key].empty? && collection_config['auto_discovered']
                        end

        if should_delete
          Logger.info "📂 #{'Ignored'.yellow} #{key.bold} collection"
          collections_config.delete(key)
        else
          count = collections[key]&.length || 0
          Logger.info "📁 Processed #{key.bold} collection with #{count} files"
        end
      end
    end

    def document_type(doc)
      if IS_JEKYLL_2_X_X && (doc.instance_of?(Jekyll::Post) || doc.instance_of?(Jekyll::Draft))
        :posts
      elsif doc.respond_to? :type
        doc.type
      elsif doc.respond_to?(:collection)
        doc.collection.label.to_sym
      elsif doc.instance_of?(Jekyll::Page)
        :pages
      end
    end

    def legacy_document_data(doc)
      data = doc.data.merge(
        {
          categories: doc.categories,
          tags: doc.tags,
          date: doc.date
        }
      )

      data['slug'] = doc.slug if doc.respond_to?(:slug)
      data
    end

    def legacy_doc?(doc)
      (IS_JEKYLL_3_04_X && doc.instance_of?(Jekyll::Document) && doc.collection.label == 'posts') ||
        (IS_JEKYLL_2_X_X && (doc.instance_of?(Jekyll::Draft) || doc.instance_of?(Jekyll::Post)))
    end

    def document_data(doc)
      data = if legacy_doc?(doc)
               legacy_document_data(doc)
             elsif doc.respond_to?(:data)
               doc.data
             else
               {}
             end

      defaults = @site.frontmatter_defaults.all(doc.relative_path, document_type(doc))
      defaults.merge(data)
    end

    def document_url(doc)
      doc.respond_to?(:url) ? doc.url : doc.relative_path
    end

    def document_path(doc)
      path = if doc.respond_to?(:collection) && doc.collection
               File.join(@collections_dir, doc.relative_path)
             else
               doc.relative_path
             end

      path.sub(%r{^/+}, '')
    end

    def document_to_json(doc, collection)
      base = document_data(doc).merge(
        {
          'path' => document_path(doc),
          'url' => document_url(doc),
          'collection' => collection
        }
      )

      base['id'] = doc.id if doc.respond_to? :id
      base
    end

    def all_posts
      posts = @site.posts || @site.collections['posts']
      posts.class.method_defined?(:docs) ? posts.docs : posts
    end

    def all_drafts
      drafts_paths.reduce([]) do |drafts, drafts_path|
        base_path = drafts_path.gsub(%r{(^|/)_drafts}, '')
        drafts + @reader.read_drafts(base_path)
      end
    end

    def all_pages
      html_pages = @site.pages.select do |page|
        page.html? || page.url.end_with?('/')
      end

      static_pages = @site.static_files.select do |static_page|
        STATIC_EXTENSIONS.include?(static_page.extname)
      end

      html_pages + static_pages
    end

    def data_files?
      @reader.read_data(@data_dir)&.keys&.any?
    end

    def group_by_category_folder(collection, key)
      split_path = "/_#{key}/"
      collection.group_by do |doc|
        parts = doc.relative_path.split(split_path)
        if parts.length > 1
          File.join(parts.first, key).sub(%r{^/+}, '')
        else
          key
        end
      end
    end
  end
end
