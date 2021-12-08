# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'cloudcannon-jekyll/version'

Gem::Specification.new do |spec|
  spec.name          = 'cloudcannon-jekyll'
  spec.summary       = 'CloudCannon Jekyll integration'
  spec.description   = 'Creates CloudCannon editor details for Jekyll'
  spec.version       = CloudCannonJekyll::VERSION
  spec.authors       = ['CloudCannon']
  spec.email         = ['support@cloudcannon.com']
  spec.homepage      = 'https://github.com/cloudcannon/cloudcannon-jekyll'
  spec.licenses      = ['MIT']
  spec.require_paths = ['lib']

  all_files          = `git ls-files -z`.split("\x0")
  spec.files         = all_files.reject { |f| f.match(%r{^(test|spec|features)/}) }

  spec.required_ruby_version = '>= 2.4.0'

  spec.add_dependency 'jekyll', '>= 2.4.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_development_dependency 'rubocop', '~> 0.80'
end
