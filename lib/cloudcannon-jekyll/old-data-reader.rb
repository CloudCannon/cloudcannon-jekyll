# frozen_string_literal: true

require "jekyll"

module CloudCannonJekyll
  # Reads data files and creates a collections-style hash representation
  # Aims to replicate the data reading logic in Jekyll 2.5
  class OldDataReader
    attr_reader :site

    def initialize(site)
      @site = site
      @safe = site.safe
      @content = {}
    end

    def read(dir)
      base = Jekyll.sanitized_path(@site.source, dir)
      # base = @site.in_source_dir(dir)
      read_data_to(base, @content)
      @content
    end

    def read_data_to(dir, data)
      return unless File.directory?(dir) && (!@safe || !File.symlink?(dir))

      entries = Dir.chdir(dir) do
        Dir["*.{yaml,yml,json,csv}"] + Dir["*"].select { |fn| File.directory?(fn) }
      end

      entries.each do |entry|
        path = Jekyll.sanitized_path(dir, entry)
        # path = @site.in_source_dir(dir, entry)
        next if File.symlink?(path) && @safe

        key = sanitize_filename(File.basename(entry, ".*"))
        if File.directory?(path)
          read_data_to(path, data[key] = {})
        else
          data[key] = read_data_file(path)
        end
      end
    end

    def read_data_file(path)
      {
        "path" => path,
      }
    end

    def sanitize_filename(name)
      name.gsub!(%r![^\w\s_-]+!, "")
      name.gsub!(%r!(^|\b\s)\s+($|\s?\b)!, '\\1\\2')
      name.gsub(%r!\s+!, "_")
    end
  end
end
