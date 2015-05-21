require 'bundler/setup'
Bundler.setup

require 'elasticsearch/faceted_search'
ELASTICSEARCH_INDEX = 'test_dummy_index'

RSpec.configure do |config|
  # some (optional) config here
end