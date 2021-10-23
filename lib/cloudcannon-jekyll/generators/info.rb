# frozen_string_literal: true

require 'jekyll'
require 'fileutils'
require_relative '../reader'
require_relative '../logger'

module CloudCannonJekyll
  # Generates JSON files containing build config and build output details
  class Info
    def generate_info(site)
      @site = site
      @reader = Reader.new(@site)

      @split_posts = group_by_category_folder(all_posts, 'posts')
      @split_drafts = group_by_category_folder(all_drafts, 'drafts')

      migrate_legacy_config

      pages = generate_pages
      data = generate_data

      collections_config = generate_collections_config
      collections = generate_collections(collections_config, pages)
      remove_empty_collection_config(collections_config, collections)

      info = {
        time: @site.time.iso8601,
        version: '0.0.2',
        cloudcannon: {
          name: 'cloudcannon-jekyll',
          version: CloudCannonJekyll::VERSION
        },
        generator: {
          name: 'jekyll',
          version: Jekyll::VERSION,
          environment: Jekyll.env,
          metadata: {
            markdown: @site.config['markdown'],
            kramdown: @site.config['kramdown'],
            commonmark: @site.config['commonmark']
          }
        },
        paths: {
          static: '',
          uploads: @site.config['uploads_dir'],
          data: @site.config['data_dir'],
          collections: collections_dir,
          layouts: @site.config['layouts_dir']
        },
        'collections-config' => collections_config,
        collections: collections,
        data: data,
        source: @site.config['source'].gsub(Dir.pwd, '')
      }

      info['timezone'] = @site.config['timezone'] if @site.config['timezone']
      info['base-url'] = @site.config['baseurl'] if @site.config['baseurl']
      info['_comments'] = @site.config['_comments'] if @site.config['_comments']

      if @site.config['_enabled_editors']
        info['_enabled_editors'] = @site.config['_enabled_editors']
      end

      if @site.config['_instance_values']
        info['_instance_values'] = @site.config['_instance_values']
      end

      info['_options'] = @site.config['_options'] if @site.config['_options']
      info['_inputs'] = @site.config['_inputs'] if @site.config['_inputs']

      if @site.config['_editables']
        info['_editables'] = @site.config['_editables']
      end

      if @site.config['_collection_groups']
        info['_collection_groups'] = @site.config['_collection_groups']
      end

      if @site.config['_editor']
        info['_editor'] = {
          default_path: @site.config.dig('_editor', 'default_path')
        }
      end

      if @site.config['_source_editor']
        info['_source_editor'] = {
          tab_size: @site.config.dig('_source_editor', 'tab_size'),
          show_gutter: @site.config.dig('_source_editor', 'show_gutter'),
          theme: @site.config.dig('_source_editor', 'theme')
        }
      end

      if @site.config['_array_structures']
        info['_array_structures'] = @site.config['_array_structures']
      end

      info['defaults'] = @site.config['defaults'] if @site.config['defaults']

      if @site.config['_select_data']
        # TODO: port over legacy logic
        info['_select_data'] = @site.config['_select_data']
      end

      info
    end

    def generate_collections_config
      collections = @site.config['collections']&.dup || {}
      collections_config = @site.config.dig('cloudcannon', 'collections')&.dup
      collections_config ||= {}

      collections.each_key do |key|
        # Workaround for empty collection configurations
        defaults = collections[key] || { output: false }
        collections_config[key] ||= {}
        collections_config[key] = collections_config[key].merge(defaults)

        # Ensure path for each collection config
        default_path = File.join(collections_dir, "_#{key}")
        collections_config[key]['path'] ||= default_path
        collections_config[key]['path'] = collections_config[key]['path']
                                          .gsub(%r{^/+}, '')
      end

      # Add a default pages config if not set, deleted later if empty
      collections_config['pages'] ||= {
        'output' => true,
        'filter' => 'strict',
        'path' => ''
      }

      # Add a default data config if not set, deleted later if no data files
      collections_config['data'] ||= { 'path' => data_dir }

      collections_config['posts'] ||= { 'output' => true }
      collections_config['drafts'] ||= { 'output' => true }

      posts_config = collections_config['posts']

      @split_posts.each_key do |key|
        posts_path = @split_posts[key]&.first
                                      &.relative_path
                                      &.sub(%r{(^|/)_posts.*}, '\1_posts')
        next unless posts_path

        collections_config[key] = posts_config.merge('path' => posts_path)
      end

      @split_drafts.each_key do |key|
        drafts_path = @split_drafts[key]&.first
                                        &.relative_path
                                        &.sub(%r{(^|/)_drafts.*}, '\1_drafts')

        next unless drafts_path

        collections_config[key] = posts_config.merge('path' => drafts_path)
      end

      collections_config
    end

    def drafts_paths
      paths = @split_posts.keys.map do |key|
        "/#{collections_dir}/#{key.sub(/posts$/, '_drafts')}".gsub(%r{\/+}, '/')
      end

      paths.empty? ? ["/#{collections_dir}/_drafts"] : paths
    end

    def generate_collections(collections_config, pages)
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
          # JSON.parse(JsonifyFilter.document_to_json(doc, 0, 12))
        end
      end

      if collections['pages'].empty? && !pages.empty?
        collections['pages'] = pages.map do |doc|
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
        "#{collections_dir}/#{doc.relative_path}".sub(%r{^\/+}, '')
      else
        doc.relative_path
      end
    end

    def generate_data
      cc_data = @site.config.dig('cloudcannon', 'data')
      data = if cc_data == true
               @site.data&.dup
             elsif cc_data&.is_a?(Hash)
               @site.data&.select { |key, _| cc_data.key?(key) }
             end

      data ||= {}
      data['categories'] ||= @site.categories.keys
      data['tags'] ||= @site.tags.keys

      data.each_key do |key|
        Logger.info "💾 Processed #{key.bold} data set"
      end

      data
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

    def collections_dir
      return '' if Jekyll::VERSION.start_with? '2.'

      @site.config['collections_dir']&.sub(%r{^\/+}, '') || ''
    end

    def data_dir
      @site.config['data_dir'] || '_data'
    end

    def all_posts
      posts = @site.posts || @site.collections['posts']
      posts.class.method_defined?(:docs) ? posts.docs : posts
    end

    def group_by_category_folder(collection, key)
      split_path = "/_#{key}/"
      collection.group_by do |doc|
        parts = doc.relative_path.split(split_path)
        if parts.length > 1
          "#{parts.first}/#{key}".sub(%r{^\/+}, '')
        else
          key
        end
      end
    end

    def remove_empty_collection_config(collections_config, collections)
      cc_collections = @site.config.dig('cloudcannon', 'collections') || {}

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

    def migrate_legacy_config
      add_legacy_explore_groups
    end

    # Support for the deprecated _explore configuration
    def add_legacy_explore_groups
      return if @site.config.key?('_collection_groups')

      collection_groups = @site.config.dig('_explore', 'groups')&.dup
      @site.config['_collection_groups'] = collection_groups
    end

    def data_files?
      @reader.read_data(data_dir)&.keys&.any?
    end
  end
end
