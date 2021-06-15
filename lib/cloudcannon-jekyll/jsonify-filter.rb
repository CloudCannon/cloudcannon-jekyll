# frozen_string_literal: true

require "jekyll"

module CloudCannonJekyll
  # Filter for converting Jekyll objects into JSON
  module JsonifyFilter
    STATIC_EXTENSIONS = [".html", ".htm"].freeze

    CC_JSONIFY_KEY_SWAPS = {
      "collections" => {
        "_sort_key"      => "_sort-key",
        "_subtext_key"   => "_subtext-key",
        "_image_key"     => "_image-key",
        "_image_size"    => "_image-size",
        "_singular_name" => "_singular-name",
        "_singular_key"  => "_singular-key",
        "_disable_add"   => "_disable-add",
        "_add_options"   => "_add-options",
      },
    }.freeze

    @simple_types = [
      String,
      Numeric,
      Integer,
      Float,
      Date,
      Time,
      NilClass,
      Object.const_defined?("Fixnum") ? Fixnum : nil,
    ].compact.freeze

    @document_types = [
      Jekyll::Document,
      Jekyll::Page,
      Jekyll::VERSION.start_with?("2.") ? Jekyll::Post : nil,
    ].compact.freeze

    def self.document_type?(input)
      @document_types.include?(input.class)
    end

    def self.simple_type?(input)
      @simple_types.include?(input.class) || [true, false].include?(input)
    end

    def self.static_file_to_json(input, depth, max_depth)
      path = input.relative_path.sub(%r!^\/+!, "")
      url = Jekyll::VERSION.start_with?("2.") ? "/#{path}" : input.url

      out = [
        "\"path\": #{JsonifyFilter.to_json(path, depth, max_depth)}",
        "\"url\": #{JsonifyFilter.to_json(url, depth, max_depth)}",
      ]

      "{#{out.join(",")}}"
    end

    def self.document_data_to_a(data, prevent, depth, max_depth)
      prevent += %w(content output next previous excerpt)

      out = data.map do |key, value|
        next if prevent.include? key

        prevent.push key
        next_max_depth = key == "_array_structures" ? 20 : max_depth
        "#{key.to_json}: #{JsonifyFilter.to_json(value, depth, next_max_depth)}"
      end

      out.compact
    end

    def self.legacy_post_to_json(input, depth, max_depth)
      prevent = %w(dir name path url date id categories tags)

      out = [
        "\"name\": #{JsonifyFilter.to_json(input.name, depth, max_depth)}",
        "\"path\": #{JsonifyFilter.to_json(input.path, depth, max_depth)}",
        "\"url\": #{JsonifyFilter.to_json(input.url, depth, max_depth)}",
        "\"date\": #{JsonifyFilter.to_json(input.date, depth, max_depth)}",
        "\"id\": #{JsonifyFilter.to_json(input.id, depth, max_depth)}",
        "\"categories\": #{JsonifyFilter.to_json(input.categories, depth, max_depth)}",
        "\"tags\": #{JsonifyFilter.to_json(input.tags, depth, max_depth)}",
      ]

      out += JsonifyFilter.document_data_to_a(input.data, prevent, depth, max_depth)
      "{#{out.join(",")}}"
    end

    def self.page_to_json(input, depth, max_depth)
      prevent = %w(dir name path url)

      out = [
        "\"name\": #{JsonifyFilter.to_json(input.name, depth, max_depth)}",
        "\"path\": #{JsonifyFilter.to_json(input.path, depth, max_depth)}",
        "\"url\": #{JsonifyFilter.to_json(input.url, depth, max_depth)}",
      ]

      # Merge Jekyll Defaults into data for pages (missing at v3.8.5)
      defaults = input.site.frontmatter_defaults.all(input.relative_path, :pages).tap do |default|
        default.delete("date")
      end

      data = Jekyll::Utils.deep_merge_hashes(defaults, input.data)

      out += JsonifyFilter.document_data_to_a(data, prevent, depth, max_depth)
      "{#{out.join(",")}}"
    end

    def self.document_path(input)
      collections_dir = input.site.config["collections_dir"] || ""
      if input.collection && !collections_dir.empty?
        "#{collections_dir}/#{input.relative_path}"
      else
        input.relative_path
      end
    end

    def self.document_to_json(input, depth, max_depth)
      prevent = %w(dir relative_path url collection)

      out = [
        "\"path\": #{JsonifyFilter.to_json(JsonifyFilter.document_path(input), depth, max_depth)}",
        "\"url\": #{JsonifyFilter.to_json(input.url, depth, max_depth)}",
      ]

      unless input.collection.nil?
        collection_json = JsonifyFilter.to_json(input.collection.label, depth, max_depth)
        out.push("\"collection\": #{collection_json}")
      end

      if input.respond_to? :id
        out.push("\"id\": #{JsonifyFilter.to_json(input.id, depth, max_depth)}")
      end

      out += JsonifyFilter.document_data_to_a(input.data, prevent, depth, max_depth)
      "{#{out.join(",")}}"
    end

    def self.array_to_json(input, depth, max_depth, key_swaps = {})
      array = input.map do |value|
        JsonifyFilter.to_json(value, depth, max_depth, key_swaps)
      end

      "[#{array.join(",")}]"
    end

    def self.hash_to_json(input, depth, max_depth, key_swaps = {})
      out = input.map do |key, value|
        next_max_depth = key == "_array_structures" ? 20 : max_depth
        string_key = (key_swaps[key] || key).to_s.to_json
        "#{string_key}: #{JsonifyFilter.to_json(value, depth, next_max_depth, key_swaps)}"
      end

      "{#{out.join(",")}}"
    end

    def self.config_to_select_data_json(input, depth)
      prevent = %w(source destination collections_dir cache_dir plugins_dir layouts_dir data_dir
                   includes_dir collections safe include exclude keep_files encoding markdown_ext
                   strict_front_matter show_drafts limit_posts future unpublished whitelist
                   plugins markdown highlighter lsi excerpt_separator incremental detach port host
                   baseurl show_dir_listing permalink paginate_path timezone quiet verbose defaults
                   liquid kramdown title url description uploads_dir _comments _options _editor
                   _explore _source_editor _array_structures maruku redcloth rdiscount redcarpet
                   gems plugins cloudcannon _collection_groups)

      out = input.map do |key, value|
        next unless value.is_a?(Array) || value.is_a?(Hash)
        next if prevent.include? key

        prevent.push key
        "#{key.to_s.to_json}: #{JsonifyFilter.to_json(value, depth)}"
      end

      out.compact!

      "{#{out.join(",")}}" if out.any?
    end

    def self.to_json(input, depth, max_depth = 9, key_swaps = {})
      depth += 1

      if depth > max_depth || (depth > 3 && JsonifyFilter.document_type?(input))
        '"MAXIMUM_DEPTH"'
      elsif JsonifyFilter.simple_type?(input)
        input.to_json
      elsif input.is_a?(Jekyll::StaticFile)
        JsonifyFilter.static_file_to_json(input, depth, max_depth)
      elsif input.is_a?(Jekyll::Page)
        JsonifyFilter.page_to_json(input, depth, max_depth)
      elsif Jekyll::VERSION.start_with?("2.") && input.is_a?(Jekyll::Post)
        JsonifyFilter.legacy_post_to_json(input, depth, max_depth)
      elsif input.is_a?(Jekyll::Document)
        JsonifyFilter.document_to_json(input, depth, max_depth)
      elsif input.is_a?(Array)
        JsonifyFilter.array_to_json(input, depth, max_depth, key_swaps)
      elsif input.is_a?(Hash)
        JsonifyFilter.hash_to_json(input, depth, max_depth, key_swaps)
      else
        input.class.to_s.prepend("UNSUPPORTED:").to_json
      end
    end

    def cc_static_files_jsonify(input)
      out = input.map do |page|
        JsonifyFilter.to_json(page, 1) if STATIC_EXTENSIONS.include?(page.extname)
      end

      out.compact!

      "[#{out.join(",")}]"
    end

    def cc_select_data_jsonify(input)
      if input.key? "_select_data"
        JsonifyFilter.to_json(input["_select_data"], 0)
      else
        JsonifyFilter.config_to_select_data_json(input, 0)
      end
    end

    def cc_jsonify(input, key_swaps_key = nil, max_depth = 8)
      if CC_JSONIFY_KEY_SWAPS.key? key_swaps_key
        JsonifyFilter.to_json(input, 0, max_depth, CC_JSONIFY_KEY_SWAPS[key_swaps_key])
      else
        JsonifyFilter.to_json(input, 0, max_depth)
      end
    end
  end
end
