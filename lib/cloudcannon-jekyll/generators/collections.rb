# frozen_string_literal: true

require 'fileutils'
require_relative '../readers/reader'
require_relative '../logger'
require_relative 'paths'

module CloudCannonJekyll
  # Helper functions for generating collection configuration and summaries
  class Collections
    def initialize(site)
      @site = site
      @config = site.config
      @reader = Reader.new(site)
      @collections_dir = Paths.collections_dir(site)
      @data_dir = Paths.data_dir(site)
      @split_posts = group_by_category_folder(all_posts, 'posts')
      @split_drafts = group_by_category_folder(all_drafts, 'drafts')
    end

    def generate_collections_config
      collections = @config['collections']&.dup || {}
      collections_config = @config.dig('cloudcannon', 'collections')&.dup
      collections_config ||= {}

      collections.each_key do |key|
        # Workaround for empty collection configurations
        defaults = collections[key] || { output: false }
        collections_config[key] ||= {}
        collections_config[key] = collections_config[key].merge(defaults)

        # Ensure path for each collection config
        default_path = File.join(@collections_dir, "_#{key}")
        collections_config[key]['path'] ||= default_path
        collections_config[key]['path'] = collections_config[key]['path'].gsub(%r{^/+}, '')
      end

      collections_config['pages'] ||= {
        'path' => '',
        'output' => true,
        'filter' => 'strict'
      }

      collections_config['data'] ||= {
        'path' => @data_dir,
        'output' => false
      }

      collections_config['posts'] ||= {
        'path' => File.join(@collections_dir, '_posts'),
        'output' => true
      }

      collections_config['drafts'] ||= {
        'path' => File.join(@collections_dir, '_drafts'),
        'output' => @config['drafts']
      }

      @split_posts.each_key do |key|
        posts_path = @split_posts[key]&.first&.relative_path&.sub(%r{(^|/)_posts.*}, '\1_posts')
        next unless posts_path

        collections_config[key] = collections_config['posts'].merge('path' => posts_path)
      end

      @split_drafts.each_key do |key|
        drafts_path = @split_drafts[key]&.first&.relative_path&.sub(%r{(^|/)_drafts.*}, '\1_drafts')
        next unless drafts_path

        collections_config[key] = collections_config['posts'].merge('path' => drafts_path)
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
        collections['pages'] = generate_pages.map do |doc|
          document_to_json(doc, 'pages')
        end
      end

      collections
    end

    def document_to_json(doc, collection)
      base = doc.data.merge(
        {
          'path' => document_path(doc),
          'url' => doc.url,
          'collection' => collection
        }
      )

      base['id'] = doc.id if doc.respond_to? :id
      base
    end

    def document_path(doc)
      if doc.respond_to?(:collection) && doc.collection
        File.join(@collections_dir, doc.relative_path).sub(%r{^/+}, '')
      else
        doc.relative_path
      end
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

    def generate_pages
      html_pages = @site.pages.select do |page|
        page.html? || page.url.end_with?('/')
      end

      static_pages = @site.static_files.select do |static_page|
        JsonifyFilter::STATIC_EXTENSIONS.include?(static_page.extname)
      end

      html_pages + static_pages
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

    def remove_empty_collection_config(collections_config, collections)
      cc_collections = @config.dig('cloudcannon', 'collections') || {}

      collections_config.each_key do |key|
        should_delete = if key == 'data'
                          !data_files?
                        else
                          collections[key].empty? && !cc_collections.key?(key)
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

    def data_files?
      @reader.read_data(@data_dir)&.keys&.any?
    end
  end
end
