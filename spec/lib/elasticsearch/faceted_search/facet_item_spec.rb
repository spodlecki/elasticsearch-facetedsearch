require 'spec_helper'

describe Elasticsearch::FacetedSearch::FacetItem do
  let(:klass) { Elasticsearch::FacetedSearch::FacetItem }
  let(:item) { {id: 't', term: "Yes", count: 476} }
  let(:key) { :hd }
  let(:group) { Object.new }
  let(:model) { klass.new(group, item) }
  let(:mappings) { Elasticsearch::FacetedSearch::FacetGroup::OPERATOR_MAPPING }

  before(:each) do
    allow(group).to receive(:key) { key }
  end

  describe "#initialize" do
    it "sets #group" do
      expect(model.group).to eq(group)
    end
    it "sets #object" do
      expect(model.object.id).to eq(item[:id])
      expect(model.object.term).to eq(item[:term])
      expect(model.object.count).to eq(item[:count])
    end
  end

  describe "#selected?" do
    describe "as string" do
      before(:each) do
        expect(group).to receive(:group_params) { 't' }
      end

      it "returns true when id matches" do
        expect(model.id).to eq('t')
        expect(model.selected?).to eq(true)
      end

      it "returns false when id is not found" do
        expect(model).to receive(:id) { 'fff' }
        expect(model.selected?).to eq(false)
      end

    end
    describe "as array" do
      before(:each) do
        expect(group).to receive(:group_params) { ['f','t'] }
      end
      it "returns true when id matches" do
        expect(model.selected?).to eq(true)
      end
      it "returns false when id is not found" do
        expect(model).to receive(:id) { 'fff' }
        expect(model.selected?).to eq(false)
      end
    end
  end

  describe "#params_for" do
    describe ":unselected" do
      before(:each) do
        expect(group).to receive(:group_params).at_least(:once) { ['f'] }
        allow(group).to receive(:operator_mappings) { '|' }
      end
      it "calls add_multivalue when 'multivalue'" do
        expect(group).to receive(:type) { 'multivalue' }
        expect(model).to receive(:add_multivalue).and_call_original
        model.params_for
      end
      it "calls add_multivalue(:and) when 'multivalue_and'" do
        expect(group).to receive(:type) { 'multivalue_and' }
        expect(model).to receive(:add_multivalue).with(:and).and_call_original
        model.params_for
      end
      it "calls add_multivalue(:or) when 'multivalue_or'" do
        expect(group).to receive(:type) { 'multivalue_or' }
        expect(model).to receive(:add_multivalue).with(:or).and_call_original
        model.params_for
      end
      it "calls add_singlevalue when 'exclusive_or'" do
        expect(group).to receive(:type) { 'exclusive_or' }
        expect(model).to receive(:add_singlevalue).and_call_original
        model.params_for
      end
    end

    describe ":selected" do
      before(:each) do
        expect(group).to receive(:group_params).at_least(:once) { ['f','t'] }
        allow(group).to receive(:operator_mappings) { '|' }
      end
      it "calls remove_multivalue when 'multivalue'" do
        expect(group).to receive(:type) { 'multivalue' }
        expect(model).to receive(:remove_multivalue).and_call_original
        model.params_for
      end
      it "calls remove_multivalue(:and) when 'multivalue_and'" do
        expect(group).to receive(:type) { 'multivalue_and' }
        expect(model).to receive(:remove_multivalue).with(:and).and_call_original
        model.params_for
      end
      it "calls remove_multivalue(:or) when 'multivalue_or'" do
        expect(group).to receive(:type) { 'multivalue_or' }
        expect(model).to receive(:remove_multivalue).with(:or).and_call_original
        model.params_for
      end
      it "calls remove_singlevalue when 'exclusive_or'" do
        expect(group).to receive(:type) { 'exclusive_or' }
        expect(model).to receive(:remove_singlevalue).and_call_original
        model.params_for
      end
    end
  end

  describe "#remove_multivalue" do
    describe ":and" do
      it "moves a value but keeps the rest" do
        expect(group).to receive(:operator_mappings).with(:and) { mappings[:and] }
        expect(group).to receive(:group_params) { ['1','2','3'] }
        expect(model).to receive(:id).at_least(:once) { 1 }
        expect(model.send(:remove_multivalue, :and)).to eq({hd: "2#{mappings[:and]}3"})
      end
      it "returns an empty hash if params is empty" do
        expect(group).to receive(:operator_mappings) { mappings[:and] }
        expect(group).to receive(:group_params) { ['1'] }
        expect(model).to receive(:id).at_least(:once) { 1 }
        expect(model.send(:remove_multivalue, :and)).to eq({hd: nil})
      end
    end

    describe ":or" do
      it "moves a value but keeps the rest" do
        expect(group).to receive(:operator_mappings).with(:or) { mappings[:or] }
        expect(group).to receive(:group_params) { ['1','2','3'] }
        expect(model).to receive(:id).at_least(:once) { 1 }
        expect(model.send(:remove_multivalue, :or)).to eq({hd: "2#{mappings[:or]}3"})
      end
      it "returns an empty hash if params is empty" do
        expect(group).to receive(:operator_mappings) { mappings[:and] }
        expect(group).to receive(:group_params) { ['1'] }
        expect(model).to receive(:id).at_least(:once) { 1 }
        expect(model.send(:remove_multivalue, :or)).to eq({hd: nil})
      end
    end
  end

  describe "#remove_singlevalue" do
    it "returns a single hash" do
      expect(model.send(:remove_singlevalue)).to eq({hd: nil})
    end
  end

  describe "#add_multivalue" do
    describe ":and" do
      it "adds a value to the array" do
        expect(model).to receive(:operator_mappings).with(:and) { mappings[:and] }
        expect(group).to receive(:group_params) { ['2','3'] }
        expect(model).to receive(:id).at_least(:once) { 1 }
        expect(model.send(:add_multivalue, :and)).to eq({hd: "2#{mappings[:and]}3#{mappings[:and]}1"})
      end
      it "returns a single hash if params is empty" do
        expect(model).to receive(:operator_mappings) { mappings[:and] }
        expect(group).to receive(:group_params) { [] }
        expect(model).to receive(:id).at_least(:once) { 1 }
        expect(model.send(:add_multivalue, :and)).to eq({hd: "1"})
      end
    end

    describe ":or" do
      it "adds a value to the array" do
        expect(model).to receive(:operator_mappings).with(:or) { mappings[:or] }
        expect(group).to receive(:group_params) { ['2','3'] }
        expect(model).to receive(:id).at_least(:once) { 1 }
        expect(model.send(:add_multivalue, :or)).to eq({hd: "2#{mappings[:or]}3#{mappings[:or]}1"})
      end
      it "returns a single hash if params is empty" do
        expect(model).to receive(:operator_mappings) { mappings[:and] }
        expect(group).to receive(:group_params) { [] }
        expect(model).to receive(:id).at_least(:once) { 1 }
        expect(model.send(:add_multivalue, :or)).to eq({hd: "1"})
      end
    end
  end

  describe "#add_singlevalue" do
    it "returns a single k/v pair" do
      expect(model.send(:add_singlevalue)).to eq({hd: 't'})
    end
  end

  describe "#matches?" do
    it "compares a value to #id" do
      expect(model.send(:matches?, 't')).to eq(true)
    end
    it "typecasts both to a string" do
      expect(model).to receive(:id) { 'false' }
      expect(model.send(:matches?, false)).to eq(true)
    end
  end
end
