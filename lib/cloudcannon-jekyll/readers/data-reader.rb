# frozen_string_literal: true

require "jekyll"

module CloudCannonJekyll
  # Reads data files and creates a collections-style hash representation
  class DataReader < Jekyll::DataReader
    # Determines how to read a data file.
    # This is overridden return a hash instead of reading the file.
    #
    # Returns a hash with the path to the data file.
    def read_data_file(path)
      {
        "path" => path,
      }
    end
  end
end
