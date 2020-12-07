# frozen_string_literal: true

require "jekyll"

begin
  require_relative "readers/data-reader"
rescue NameError
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
      CloudCannonJekyll::DataReader.new(@site).read(dir)
    rescue NameError # DataReader doesn't exist in old versions of Jekyll
      CloudCannonJekyll::OldDataReader.new(@site).read(dir)
    end

    def read_drafts(dir = "")
      Jekyll::PostReader.new(@site).read_drafts(dir)
    rescue NameError # PostReader doesn't exist in old versions of Jekyll
      @site.read_content(dir, "_drafts", Jekyll::Draft)
    end

    def read_posts(dir = "")
      Jekyll::PostReader.new(@site).read_posts(dir)
    rescue NameError # PostReader doesn't exist in old versions of Jekyll
      @site.read_content(dir, "_posts", Jekyll::Post)
    end
  end
end
