require 'spec_helper'

class DummyFacets
  include Elasticsearch::FacetedSearch::FacetBase
  facet_exclusive_or(:hd, 'media_hd', 'HD Media')

  #mock
  def type
    ['type_here']
  end

  #mock
  def filter_hd?
  end

  #mock
  def hd_value
    true
  end
end

describe Elasticsearch::FacetedSearch::FacetBase do
  let(:klass) { DummyFacets }
  let(:model) { DummyFacets.new({}) }

  describe "#class_facets" do
    it "returns class facets" do
      expect(DummyFacets).to receive(:facets) { {facet: true} }
      expect(model.class_facets).to eq({facet: true})
    end
  end

  describe "#query" do

    it "removes an empty items" do
      expect(model.query).to eq({:size=>32, :from=>0, :facets=>{:hd=>{:terms=>{:field=>"media_hd", :size=>70}}}})
    end

    describe "with facets and filters" do
      it "merges filters when filter_query has value" do
        expect(model).to receive(:filter_query).at_least(:once) { 'hi' }
        expect(model).to receive(:facet_query) { nil }
        expect(model.query).to eq({:size=>32, :from=>0, filter: {and: 'hi'}})
      end

      it "merges facets when facets has value" do
        expect(model).to receive(:filter_query) { nil }
        expect(model).to receive(:facet_query).at_least(:once) { 'hi' }
        expect(model.query).to eq({:size=>32, :from=>0, facets: 'hi'})
      end

      it "can merge both hashes" do
        expect(model).to receive(:filter_query).at_least(:once) { 'hi' }
        expect(model).to receive(:facet_query).at_least(:once) { 'hi' }
        expect(model.query).to eq({:size=>32, :from=>0, facets: 'hi', filter: {and: 'hi'}})
      end
    end
    describe "with limits" do
      before(:each) do
        expect(model).to receive(:filter_query).at_least(:once) { 'hi' }
        expect(model).to receive(:facet_query).at_least(:once) { 'hi' }
      end

      it "returns from params" do
        expect(model).to receive(:search_params).at_least(:once) { {limit: '10'}}
        expect(model.query).to eq({:size=>10, :from=>0, :filter=>{:and=>"hi"}, :facets=>"hi"})
      end

      it "defaults to 32" do
        expect(model.query).to eq({:size=>32, :from=>0, :filter=>{:and=>"hi"}, :facets=>"hi"})
      end
    end

    describe "with page" do
      before(:each) do
        expect(model).to receive(:filter_query).at_least(:once) { 'hi' }
        expect(model).to receive(:facet_query).at_least(:once) { 'hi' }
        expect(model).to receive(:search_params).at_least(:once) { {page: 10, limit: 3} }
      end

      it "returns from params" do
        expect(model.query).to eq({:size=>3, :from=>27, :filter=>{:and=>"hi"}, :facets=>"hi"})
      end
    end

    describe "with sort" do
      before(:each) do
        expect(model).to receive(:sorts).at_least(:once) {
          [
            {
              label: "Relevant",
              value: "relevant",
              search: ["_score"],
              default: false
            },
            {
              label: "updated",
              value: "updated",
              search: ["updated"],
              default: true
            }
          ]
        }
      end
      it "has a default sort" do
        expect(model.query).to eq({:size=>32, :from=>0, :sort=>["updated"], :facets=>{:hd=>{:terms=>{:field=>"media_hd", :size=>70}}}})
      end

      it "can have a selected sort" do
        expect(model).to receive(:search_params).at_least(:once) { {sort: 'relevant'} }
        expect(model.query).to eq({:size=>32, :from=>0, :sort=>["_score"], :facets=>{:hd=>{:terms=>{:field=>"media_hd", :size=>70}}}})
      end
    end
  end

  describe "#facet_query" do
    it "caches the request" do
      expect(model).to receive(:build_facets).once {'blah'}
      2.times { model.facet_query }
    end
  end

  describe "#filter_query" do
    it "caches the request" do
      expect(model).to receive(:build_filters).once {'blah'}
      2.times { model.filter_query }
    end
  end

  describe "#search_params" do
    it "returns the params" do
      expect(model).to receive(:params) { 'boom' }
      expect(model.search_params).to eq('boom')
    end
  end

  describe "#build_facets" do
    it "is private" do
      expect {
        model.build_facets
      }.to raise_error
    end
    describe "with filters" do
      it "equals a specific format" do
        expect(model).to receive(:filter_query).at_least(:once) { [{terms: {:hello => ['world']}}] }
        expect(model.send(:build_facets)).to eq(
          {
            :hd=>{
              :terms=>{
                :field=>"media_hd", :size=>70
              },
              :facet_filter=>{
                :and=>[
                  {:terms=>{:hello=>["world"]}}
                ]
              }
            }
          }
        )
      end

      # Added spec due to improper merge on 0.0.2 release
      # => if this spec is failing, elastic search is going to complain
      it "has 2 keys" do
        expect(model).to receive(:filter_query).at_least(:once) { [{terms: {:hello => ['world']}}] }
        expect(model.send(:build_facets)[:hd].keys).to eq([:terms, :facet_filter])
      end

      it "can bypass the facet_filter declaration" do
        expect(model.send(:build_facets, false)).to eq(
          {
            :hd=>{
              :terms=>{
                :field=>"media_hd", :size=>70
              }
            }
          }
        )
      end
    end
    describe "without filters" do
      before(:each) do
        expect(model).to receive(:filter_query) { [] }
      end
      it "equals a specific format" do
        expect(model.send(:build_facets)).to eq({
          :hd=>{
            :terms=>{:field=>"media_hd", :size=>70}
          }
        })
      end
    end
  end

  describe "#build_filters" do
    it "is private" do
      expect {
        model.build_filters
      }.to raise_error
    end
    describe "with #filter_XX? = true" do
      before(:each) do
        expect(model).to receive(:filter_hd?) { true }
      end

      it "returns filter hash for Elasticsearch" do
        expect(model.send(:build_filters)).to eq([{:terms=>{"media_hd"=>[true]}}])
      end
    end

    describe "with #filter_XX? = false" do
      before(:each) do
        expect(model).to receive(:filter_hd?) { false }
      end

      it "returns an empty array" do
        expect(model.send(:build_filters)).to be_blank
      end
    end
  end

  describe "#values_for" do
    it "is private" do
      expect {
        model.values_for(:hd)
      }.to raise_error
    end

    it "always returns an array" do
      expect(model).to receive(:temp_value) { 'hello' }
      expect(model.send(:values_for, :temp)).to eq(['hello'])
    end
  end

  describe "#execution_type" do
    it "is private" do
      expect {
        model.execution_type('multivalue_or')
      }.to raise_error
    end
    it "returns :or when 'multivalue_or'" do
      expect(model.send(:execution_type, 'multivalue_or')).to eq(:or)
    end

    it "returns :and when 'multivalue_and'" do
      expect(model.send(:execution_type, 'multivalue_and')).to eq(:and)
    end

    it "returns nil when 'exclusive_or'" do
      expect(model.send(:execution_type, 'exclusive_or')).to be_nil
    end
  end
end
