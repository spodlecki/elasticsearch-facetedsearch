# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elasticsearch/faceted_search/version'

Gem::Specification.new do |spec|
  spec.name          = "elasticsearch-facetedsearch"
  spec.version       = Elasticsearch::FacetedSearch::VERSION
  spec.authors       = ["s.podlecki"]
  spec.email         = ["s.podlecki@gmail.com"]
  spec.description   = %q{Add faceted searching with ElasticSearch to your Models}
  spec.summary       = %q{Quickly apply a faceted search using ElasticSearch and Models.}
  spec.homepage      = "https://github.com/spodlecki/elasticsearch-facetedsearch"
  spec.license       = "MIT"


  spec.files         = Dir["lib/**/*", "Rakefile", 'CHANGELOG.md', "README.md"]
  spec.test_files    = Dir["spec/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency 'elasticsearch-rails'
  spec.add_dependency 'elasticsearch-model'
  spec.add_dependency "rails", "> 3.2.8"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-rails"
end
