# frozen_string_literal: true

module CloudCannonJekyll
  class PageWithoutAFile < Jekyll::Page
    def read_yaml(*)
      @data ||= {}
    end
  end
end
