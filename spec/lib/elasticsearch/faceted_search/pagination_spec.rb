require 'spec_helper'

class DummyPaginatedFacets
  include Elasticsearch::FacetedSearch::FacetBase
  facet_exclusive_or(:hd, 'media_hd', 'HD Media')

  def limit
    11
  end

  #mock
  def type
    'type_here'
  end

  #mock
  def filter_hd?
  end

  #mock
  def hd_value
    true
  end
end

module Elasticsearch
  module FacetedSearch
    describe Pagination do
      let(:model) { DummyPaginatedFacets.new({}) }

      describe "#total_count" do
        it "returns hits total from ES result" do
          expect(model).to receive(:search) { {'hits' => { 'total' => 20 }} }
          expect(model.total_count).to eq(20)
        end
      end

      describe "#total_pages" do
        it "returns total number of pages" do
          expect(model).to receive(:total_count) { 25 }
          expect(model.total_pages).to eq(3)
        end
      end

      describe "#limit_value" do
        it "returns the limit from model" do
          expect(model.limit).to eq(11)
        end
      end
    end
  end
end
