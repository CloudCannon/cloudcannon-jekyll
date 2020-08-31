# frozen_string_literal: true

require "jekyll"

module CloudCannonJekyll
  module SafeJsonifyFilter
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

    def self.static_file_to_json(input, depth)
      out = [
        "\"extname\": #{SafeJsonifyFilter.to_json(input.extname, depth + 1)}",
        "\"path\": #{SafeJsonifyFilter.to_json(input.relative_path, depth + 1)}",
      ]

      # modified_time isn't defined in Jekyll 2.4.0
      if input.respond_to? :modified_time
        out.push("\"modified_time\": #{SafeJsonifyFilter.to_json(input.modified_time, depth + 1)}")
      end

      "{#{out.join(",")}}"
    end

    def self.document_data_to_json(data, out, prevent, depth)
      prevent += %w(content output next previous excerpt)

      data.each { |key, value|
        next if prevent.include? key
        prevent.push key
        out.push("#{key.to_json}: #{SafeJsonifyFilter.to_json(value, depth + 1)}")
      }

      "{#{out.join(",")}}"
    end

    def self.legacy_post_to_json(input, depth)
      prevent = %w(dir name path url date id categories tags)

      out = [
        "\"dir\": #{SafeJsonifyFilter.to_json(input.dir, depth + 1)}",
        "\"name\": #{SafeJsonifyFilter.to_json(input.name, depth + 1)}",
        "\"path\": #{SafeJsonifyFilter.to_json(input.path, depth + 1)}",
        "\"url\": #{SafeJsonifyFilter.to_json(input.url, depth + 1)}",
        "\"date\": #{SafeJsonifyFilter.to_json(input.date, depth + 1)}",
        "\"id\": #{SafeJsonifyFilter.to_json(input.id, depth + 1)}",
        "\"categories\": #{SafeJsonifyFilter.to_json(input.categories, depth + 1)}",
        "\"tags\": #{SafeJsonifyFilter.to_json(input.tags, depth + 1)}",
      ]

      SafeJsonifyFilter.document_data_to_json(input.data, out, prevent, depth)
    end

    def self.page_to_json(input, depth)
      prevent = %w(dir name path url)

      out = [
        "\"dir\": #{SafeJsonifyFilter.to_json(input.dir, depth + 1)}",
        "\"name\": #{SafeJsonifyFilter.to_json(input.name, depth + 1)}",
        "\"path\": #{SafeJsonifyFilter.to_json(input.path, depth + 1)}",
        "\"url\": #{SafeJsonifyFilter.to_json(input.url, depth + 1)}",
      ]

      # Merge Jekyll Defaults into data for pages (missing at v3.8.5)
      defaults = input.site.frontmatter_defaults.all(input.relative_path, :pages).tap do |h|
        h.delete("date")
      end

      data = Jekyll::Utils.deep_merge_hashes(defaults, input.data)
      SafeJsonifyFilter.document_data_to_json(data, out, prevent, depth)
    end

    def self.document_to_json(input, depth)
      prevent = %w(dir id relative_path url collection)

      out = [
        "\"path\": #{SafeJsonifyFilter.to_json(input.relative_path, depth + 1)}",
        "\"relative_path\": #{SafeJsonifyFilter.to_json(input.relative_path, depth + 1)}",
        "\"url\": #{SafeJsonifyFilter.to_json(input.url, depth + 1)}",
      ]

      unless input.collection.nil?
        out.push("\"collection\": #{SafeJsonifyFilter.to_json(input.collection.label, depth + 1)}")
      end

      # id isn't defined in Jekyll 2.4.0
      out.push("\"id\": #{SafeJsonifyFilter.to_json(input.id, depth + 1)}") if input.respond_to? :id

      SafeJsonifyFilter.document_data_to_json(input.data, out, prevent, depth)
    end

    def self.array_to_json(input, depth)
      array = input.map do |value|
        SafeJsonifyFilter.to_json(value, depth + 1)
      end

      "[#{array.join(",")}]"
    end

    def self.hash_to_json(input, depth)
      hash = input.map do |key, value|
        "#{key.to_json}: #{SafeJsonifyFilter.to_json(value, depth + 1)}"
      end

      "{#{hash.join(",")}}"
    end

    def self.site_drop_legacy_select_data_to_json(input, depth)
      prevent = %w(config time related_posts destination cache_dir safe
        keep_files encoding markdown_ext strict_front_matter show_drafts
        limit_posts future unpublished whitelist maruku markdown highlighter
        lsi excerpt_separator incremental detach port host show_dir_listing
        permalink paginate_path quiet verbose defaults liquid kramdown title
        url description categories data tags static_files html_pages pages
        documents posts related_posts time source timezone include exclude
        baseurl collections _comments _editor _source_editor _explore
        uploads_dir plugins_dir data_dir collections_dir includes_dir
        layouts_dir _array_structures cloudcannon rdiscount redcarpet redcloth)

      if Jekyll::VERSION.start_with?("2.")
        prevent = prevent.concat input["collections"].keys
        prevent.push "gems"
      elsif Jekyll::VERSION.match?(%r!3\.[0-4]\.!)
        prevent = prevent.concat input["collections"].map { |c| c["label"] }
        prevent = prevent.concat %w(plugins gems)
      else
        prevent.push "plugins"
      end

      out = input.map { |key, value|
        next unless value.is_a?(Array) || value.is_a?(Hash)
        next if prevent.include? key
        prevent.push key

        "#{key.to_json}: #{SafeJsonifyFilter.to_json(value, depth + 1)}"
      }.compact

      "{#{out.join(",")}}" if out.any?
    end

    def self.to_json(input, depth)
      if depth > 8 || (depth > 2 && SafeJsonifyFilter.document_type?(input))
        '"MAXIMUM_DEPTH"'
      elsif SafeJsonifyFilter.simple_type?(input)
        input.to_json
      elsif input.is_a?(Jekyll::StaticFile)
        SafeJsonifyFilter.static_file_to_json(input, depth)
      elsif input.is_a?(Jekyll::Page)
        SafeJsonifyFilter.page_to_json(input, depth)
      elsif Jekyll::VERSION.start_with?("2.") && input.is_a?(Jekyll::Post)
        SafeJsonifyFilter.legacy_post_to_json(input, depth)
      elsif input.is_a?(Jekyll::Document)
        SafeJsonifyFilter.document_to_json(input, depth)
      elsif input.is_a?(Array)
        SafeJsonifyFilter.array_to_json(input, depth)
      elsif input.is_a?(Hash)
        SafeJsonifyFilter.hash_to_json(input, depth)
      else
        "\"UNSUPPORTED:#{input.class.to_json}\""
      end
    end

    def cc_static_files_jsonify(input)
      out = []
      input.each do |page|
        next if page.extname != ".html" &&
          page.extname != ".htm" &&
          page.path != "/robots.txt" &&
          page.path != "/sitemap.xml"

        out.push(SafeJsonifyFilter.to_json(page, 1))
      end

      "[#{out.join(",")}]"
    end

    def cc_site_select_data_jsonify(input)
      if input.key? "_select_data"
        SafeJsonifyFilter.to_json(input["_select_data"], 0)
      else
        SafeJsonifyFilter.site_drop_legacy_select_data_to_json(input, 0)
      end
    end

    def cc_safe_jsonify(input)
      SafeJsonifyFilter.to_json(input, 0)
    end
  end
end
