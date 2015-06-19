require 'bundler/setup'
Bundler.setup

if ENV['CODECLIMATE_REPO_TOKEN']
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

require 'elasticsearch/faceted_search'
ELASTICSEARCH_INDEX = 'test_dummy_index'


RSpec.configure do |config|
  # some (optional) config here
end