# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "cloudcannon-jekyll/version"

Gem::Specification.new do |spec|
  spec.name          = "cloudcannon-jekyll"
  spec.summary       = "CloudCannon Jekyll integration"
  spec.description   = "Creates CloudCannon editor details for Jekyll"
  spec.version       = CloudCannonJekyll::VERSION
  spec.authors       = ["CloudCannon"]
  spec.email         = ["support@cloudcannon.com"]
  spec.homepage      = "https://github.com/cloudcannon/cloudcannon-jekyll"
  spec.licenses      = ["MIT"]
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r!^(test|spec|features)/!) }
  spec.require_paths = ["lib"]
  spec.add_dependency "jekyll", ">= 2.4.0", "< 5"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.9"
  spec.add_development_dependency "rubocop", "~> 0.71"
  spec.add_development_dependency "rubocop-jekyll", "~> 0.10"
end
