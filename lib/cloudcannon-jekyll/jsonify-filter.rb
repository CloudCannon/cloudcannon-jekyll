# frozen_string_literal: true

require "jekyll"

module CloudCannonJekyll
  module JsonifyFilter
    CC_JSONIFY_KEY_SWAPS = {
      "collections" => {
        "_sort_key"      => "_sort-key",
        "_subtext_key"   => "_subtext-key",
        "_image_key"     => "_image-key",
        "_image_size"    => "_image-size",
        "_singular_name" => "_singular-name",
        "_singular_key"  => "_singular-key",
        "_disable_add"   => "_disable-add",
        "_icon"          => "_icon",
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
    ].freeze

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

    def self.static_file_to_json(input, depth)
      out = [
        "\"extname\": #{JsonifyFilter.to_json(input.extname, depth + 1)}",
        "\"path\": #{JsonifyFilter.to_json(input.relative_path, depth + 1)}",
      ]

      # modified_time isn't defined in Jekyll 2.4.0
      if input.respond_to? :modified_time
        out.push("\"modified_time\": #{JsonifyFilter.to_json(input.modified_time, depth + 1)}")
      end

      "{#{out.join(",")}}"
    end

    def self.document_data_to_json(data, out, prevent, depth)
      prevent += %w(content output next previous excerpt)

      data.each do |key, value|
        next if prevent.include? key

        prevent.push key
        out.push("#{key.to_json}: #{JsonifyFilter.to_json(value, depth + 1)}")
      end

      "{#{out.join(",")}}"
    end

    def self.legacy_post_to_json(input, depth)
      prevent = %w(dir name path url date id categories tags)

      out = [
        "\"dir\": #{JsonifyFilter.to_json(input.dir, depth + 1)}",
        "\"name\": #{JsonifyFilter.to_json(input.name, depth + 1)}",
        "\"path\": #{JsonifyFilter.to_json(input.path, depth + 1)}",
        "\"url\": #{JsonifyFilter.to_json(input.url, depth + 1)}",
        "\"date\": #{JsonifyFilter.to_json(input.date, depth + 1)}",
        "\"id\": #{JsonifyFilter.to_json(input.id, depth + 1)}",
        "\"categories\": #{JsonifyFilter.to_json(input.categories, depth + 1)}",
        "\"tags\": #{JsonifyFilter.to_json(input.tags, depth + 1)}",
      ]

      JsonifyFilter.document_data_to_json(input.data, out, prevent, depth)
    end

    def self.page_to_json(input, depth)
      prevent = %w(dir name path url)

      out = [
        "\"dir\": #{JsonifyFilter.to_json(input.dir, depth + 1)}",
        "\"name\": #{JsonifyFilter.to_json(input.name, depth + 1)}",
        "\"path\": #{JsonifyFilter.to_json(input.path, depth + 1)}",
        "\"url\": #{JsonifyFilter.to_json(input.url, depth + 1)}",
      ]

      # Merge Jekyll Defaults into data for pages (missing at v3.8.5)
      defaults = input.site.frontmatter_defaults.all(input.relative_path, :pages).tap do |h|
        h.delete("date")
      end

      data = Jekyll::Utils.deep_merge_hashes(defaults, input.data)
      JsonifyFilter.document_data_to_json(data, out, prevent, depth)
    end

    def self.document_to_json(input, depth)
      prevent = %w(dir id relative_path url collection)

      out = [
        "\"path\": #{JsonifyFilter.to_json(input.relative_path, depth + 1)}",
        "\"relative_path\": #{JsonifyFilter.to_json(input.relative_path, depth + 1)}",
        "\"url\": #{JsonifyFilter.to_json(input.url, depth + 1)}",
      ]

      unless input.collection.nil?
        out.push("\"collection\": #{JsonifyFilter.to_json(input.collection.label, depth + 1)}")
      end

      # id isn't defined in Jekyll 2.4.0
      out.push("\"id\": #{JsonifyFilter.to_json(input.id, depth + 1)}") if input.respond_to? :id

      JsonifyFilter.document_data_to_json(input.data, out, prevent, depth)
    end

    def self.array_to_json(input, depth, key_swaps = {})
      array = input.map do |value|
        JsonifyFilter.to_json(value, depth + 1, key_swaps)
      end

      "[#{array.join(",")}]"
    end

    def self.hash_to_json(input, depth, key_swaps = {})
      hash = input.map do |key, value|
        "#{(key_swaps[key] || key).to_json}: #{JsonifyFilter.to_json(value, depth + 1, key_swaps)}"
      end

      "{#{hash.join(",")}}"
    end

    def self.config_to_select_data_json(input, depth)
      prevent = %w(source destination collections_dir cache_dir plugins_dir layouts_dir data_dir
                   includes_dir collections safe include exclude keep_files encoding markdown_ext
                   strict_front_matter show_drafts limit_posts future unpublished whitelist
                   plugins markdown highlighter lsi excerpt_separator incremental detach port host
                   baseurl show_dir_listing permalink paginate_path timezone quiet verbose defaults
                   liquid kramdown title url description uploads_dir _comments _options _editor
                   _explore _source_editor _array_structures maruku redcloth rdiscount redcarpet
                   gems plugins)

      out = input.map do |key, value|
        next unless value.is_a?(Array) || value.is_a?(Hash)
        next if prevent.include? key

        prevent.push key
        "#{key.to_json}: #{JsonifyFilter.to_json(value, depth + 1)}"
      end

      out.compact

      "{#{out.join(",")}}" if out.any?
    end

    def self.to_json(input, depth, key_swaps = {})
      if depth > 8 || (depth > 2 && JsonifyFilter.document_type?(input))
        '"MAXIMUM_DEPTH"'
      elsif JsonifyFilter.simple_type?(input)
        input.to_json
      elsif input.is_a?(Jekyll::StaticFile)
        JsonifyFilter.static_file_to_json(input, depth)
      elsif input.is_a?(Jekyll::Page)
        JsonifyFilter.page_to_json(input, depth)
      elsif Jekyll::VERSION.start_with?("2.") && input.is_a?(Jekyll::Post)
        JsonifyFilter.legacy_post_to_json(input, depth)
      elsif input.is_a?(Jekyll::Document)
        JsonifyFilter.document_to_json(input, depth)
      elsif input.is_a?(Array)
        JsonifyFilter.array_to_json(input, depth, key_swaps)
      elsif input.is_a?(Hash)
        JsonifyFilter.hash_to_json(input, depth, key_swaps)
      else
        input.class.to_s.prepend("UNSUPPORTED:").to_json
      end
    end

    def cc_static_files_jsonify(input)
      out = []
      input.each do |page|
        next if page.extname != ".html" &&
          page.extname != ".htm" &&
          page.path != "/robots.txt" &&
          page.path != "/sitemap.xml"

        out.push(JsonifyFilter.to_json(page, 1))
      end

      "[#{out.join(",")}]"
    end

    def cc_select_data_jsonify(input)
      if input.key? "_select_data"
        JsonifyFilter.to_json(input["_select_data"], 0)
      else
        JsonifyFilter.config_to_select_data_json(input, 0)
      end
    end

    def cc_jsonify(input, key_swaps_key = nil)
      if CC_JSONIFY_KEY_SWAPS.key? key_swaps_key
        JsonifyFilter.to_json(input, 0, CC_JSONIFY_KEY_SWAPS[key_swaps_key])
      else
        JsonifyFilter.to_json(input, 0)
      end
    end
  end
end
