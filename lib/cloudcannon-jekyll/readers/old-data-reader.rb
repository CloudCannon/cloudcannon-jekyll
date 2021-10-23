# frozen_string_literal: true

if Jekyll::VERSION.start_with? '2.'
  require 'jekyll'

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
        read_data_to(base, @content)
        @content
      end

      def read_data_to(dir, data)
        return unless File.directory?(dir) && (!@safe || !File.symlink?(dir))

        entries = Dir.chdir(dir) do
          Dir['*.{yaml,yml,json,csv}'] + Dir['*'].select do |fn|
            File.directory?(fn)
          end
        end

        entries.each do |entry|
          path = Jekyll.sanitized_path(dir, entry)
          next if File.symlink?(path) && @safe

          key = sanitize_filename(File.basename(entry, '.*'))
          if File.directory?(path)
            read_data_to(path, data[key] = {})
          else
            data[key] = read_data_file(path)
          end
        end
      end

      def read_data_file(path)
        {
          'path' => path
        }
      end

      def sanitize_filename(name)
        name.gsub!(/[^\w\s_-]+/, '')
        name.gsub!(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
        name.gsub(/\s+/, '_')
      end
    end
  end
end
