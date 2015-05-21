# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elasticsearch/faceted_search/version'

Gem::Specification.new do |spec|
  spec.name          = "elasticsearch-facetedsearch"
  spec.version       = Elasticsearch::FacetedSearch::VERSION
  spec.authors       = ["s.podlecki"]
  spec.email         = ["s.podlecki@gmail.com"]
  spec.description   = %q{Quickly add faceted searching with ElasticSearch}
  spec.summary       = %q{Quickly add faceted searching with ElasticSearch}
  spec.homepage      = ""
  spec.license       = "MIT"

  file_list = `git ls-files`.split($/)

  spec.files         = file_list
  spec.executables   = file_list.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = file_list.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'elasticsearch-rails', '0.1.7'
  spec.add_dependency 'elasticsearch-model', '0.1.7'
  spec.add_dependency "rails", "> 3.2.8"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency 'geminabox'
end
