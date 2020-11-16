# frozen_string_literal: true

require "jekyll"

if !Jekyll::VERSION.start_with? "2."
  require_relative "readers/data-reader"
else
  require_relative "readers/old-data-reader"
end

module CloudCannonJekyll
  # Wraps read functions into one class
  class Reader
    attr_reader :site

    def initialize(site)
      @site = site
    end

    def read_data(dir = "_data")
      if Jekyll::VERSION.start_with? "2."
        CloudCannonJekyll::OldDataReader.new(@site).read(dir)
      else
        CloudCannonJekyll::DataReader.new(@site).read(dir)
      end
    end

    def read_drafts(dir = "")
      if Jekyll::VERSION.start_with? "2."
        @site.read_content(dir, "_drafts", Jekyll::Draft)
      else
        Jekyll::PostReader.new(@site).read_drafts(dir)
      end
    end

    def read_posts(dir = "")
      if Jekyll::VERSION.start_with? "2."
        @site.read_content(dir, "_posts", Jekyll::Post)
      else
        Jekyll::PostReader.new(@site).read_posts(dir)
      end
    end
  end
end
