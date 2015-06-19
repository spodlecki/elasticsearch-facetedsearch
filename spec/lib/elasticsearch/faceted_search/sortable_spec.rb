require 'spec_helper'

class DummySortable
  include Elasticsearch::FacetedSearch::Sortable

  def sorts
    [
      {
        label: "Recent",
        value: "updated",
        search: [
          { published_at: {order: :asc}},
          "_score"
        ],
        default: true
      },
      {
        label: "Relevant",
        value: "relevant",
        search: [ "_score" ],
        default: false
      }
    ]
  end

end

describe Elasticsearch::FacetedSearch::Sortable do
  let(:model) { DummySortable.new }

  describe "#sorts" do
    it "is not an empty array" do
      expect(model.sorts).not_to be_empty
    end
  end

  describe "#current_sort_for_search" do
    it "returns the search for default value" do
      expect(model).to receive(:search_params).at_least(:once) { {sort: ''} }
      expect(model.current_sort_for_search).to eq([{:published_at=>{:order=>:asc}}, "_score"])
    end

    it "returns the default sort when random string given" do
      expect(model).to receive(:search_params).at_least(:once) { {sort: 'boom-chacka!'} }
      expect(model.current_sort_for_search).to eq([{:published_at=>{:order=>:asc}}, "_score"])
    end

    it "returns the selected sort when valid" do
      expect(model).to receive(:search_params).at_least(:once) { {sort: 'relevant'} }
      expect(model.current_sort_for_search).to eq([ "_score" ])
    end

    it "returns nil if no #current_sort" do
      expect(model).to receive(:current_sort) { false }
      expect(model.current_sort_for_search).to be_nil
    end
  end

  describe "#current_sort" do
    it "fetches the default if nothing given" do
      expect(model).to receive(:selected_sort_value).at_least(:once) { 'blah' }
      expect(model.send(:current_sort)).to eq(model.send(:default_sort))
    end

    it "fetches the selected if valid" do
      expect(model).to receive(:selected_sort_value).at_least(:once) { 'relevant' }
      expect(model.send(:current_sort)).to eq(model.sorts.last)
    end
  end

  describe "#selected_sort_value" do
    it "is private" do
      expect {
        model.selected_sort_value
      }.to raise_error(NoMethodError)
    end
    it "returns the sort from search params" do
      expect(model).to receive(:search_params).at_least(:once) { {sort: 'hi'} }
      expect(model.send(:selected_sort_value)).to eq('hi')
    end
    it "returns a default if no sort param" do
      expect(model).to receive(:search_params).at_least(:once) { {sort: ''} }
      expect(model.send(:selected_sort_value)).to eq('updated')
    end
  end

  describe "#sort_param" do
    it "is private" do
      expect {
        model.sort_param
      }.to raise_error(NoMethodError)
    end
    it "returns the sort param" do
      expect(model).to receive(:search_params) { {sort: 'hi'} }
      expect(model.send(:sort_param)).to eq('hi')
    end
    it "returns nil if no param exists" do
      expect(model).to receive(:search_params) { {} }
      expect(model.send(:sort_param)).to be_nil
    end
  end

  describe "#default_sort_value" do
    it "is private" do
      expect {
        model.default_sort_value
      }.to raise_error(NoMethodError)
    end
    it "matches the default config" do
      expect(model.send(:default_sort_value)).to eq('updated')
    end
  end

  describe "#default_sort" do
    it "is private" do
      expect {
        model.default_sort
      }.to raise_error(NoMethodError)
    end
    it "matches the default config" do
      expect(model.send(:default_sort)).to eq(model.sorts.first)
    end
  end
end
