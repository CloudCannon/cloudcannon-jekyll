# frozen_string_literal: true

require 'jekyll'

module CloudCannonJekyll
  # Logging helpers
  class Logger
    def self.info(str)
      Jekyll.logger.info('CloudCannon:', str)
    end

    def self.warn(str)
      Jekyll.logger.warn('CloudCannon:', str)
    end
  end
end
