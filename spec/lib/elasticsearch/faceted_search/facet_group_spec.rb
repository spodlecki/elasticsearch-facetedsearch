require 'spec_helper'

describe Elasticsearch::FacetedSearch::FacetGroup do
  let(:klass) { Elasticsearch::FacetedSearch::FacetGroup }
  let(:objects) { {"_type"=>"terms", "missing"=>0, "total"=>476, "other"=>0, "terms"=>[{"term"=>"t", "count"=>476}, {"term"=>"f", "count"=>5}, {"term"=>"F", "count"=>476}]} }
  let(:key) { 'hd' }
  let(:search) { Object.new }
  let(:model) { klass.new(search, key, objects) }

  describe "#initializer" do
    it "sets search" do
      expect(model.search).to eq(search)
    end
    it "symbolizes the key" do
      expect(key).to be_a(String)
      expect(model.key).to eq(:hd)
    end
    it "sets the objects from the terms key" do
      expect(model.objects).to eq({"t"=>476, "f"=>481})
    end
  end

  describe "#items" do
    it "builds the items" do
      expect(model).to receive(:build_items).and_call_original
      model.items
    end
  end

  describe "#title" do
    it "returns title set in class" do
      expect(search).to receive(:class_facets) { {hd: {title: 'HD Media'}} }
      expect(model.title).to eq('HD Media')
    end
    it "returns the key humanized if no key exists" do
      expect(search).to receive(:class_facets) { {} }
      expect(model.title).to eq('Hd')
    end
  end

  describe "#selected_values" do
    describe ":and" do
      before(:each) do
        expect(model).to receive(:operator).at_least(:once) { ',' }
      end
      it "returns array of selected items" do
        expect(search).to receive(:search_params) { {hd: 'F,T'} }
        expect(model.selected_values).to eq(['f','t'])
      end
      it "returns nothing when no key exists" do
        expect(search).to receive(:search_params) { {hello: '1,2'} }
        expect(model.selected_values).to eq([])
      end
      pending "only returns valid keys" do
        expect(search).to receive(:search_params) { {hd: 'F,T,L'} }
        expect(model.selected_values).to eq(['f','t'])
      end
    end

    describe ":or" do
      before(:each) do
        expect(model).to receive(:operator).at_least(:once) { '|' }
      end
      it "returns array of selected items" do
        expect(search).to receive(:search_params) { {hd: 'F|T'} }
        expect(model.selected_values).to eq(['f','t'])
      end
      it "returns nothing when no key exists" do
        expect(search).to receive(:search_params) { {hello: '1|2'} }
        expect(model.selected_values).to eq([])
      end
      pending "only returns valid keys" do
        expect(search).to receive(:search_params) { {hd: 'F|T|L'} }
        expect(model.selected_values).to eq(['f','t'])
      end
    end

    describe "nil" do
      before(:each) do
        expect(model).to receive(:operator).at_least(:once) { nil }
      end
      it "returns array of selected items" do
        expect(search).to receive(:search_params) { {hd: 'F|T'} }
        expect(model.selected_values).to eq('f|t')
      end
      it "returns nothing when no key exists" do
        expect(search).to receive(:search_params) { {hello: '1|2'} }
        expect(model.selected_values).to eq('')
      end
      pending "only returns valid keys" do
        expect(search).to receive(:search_params) { {hd: 'F|T|L'} }
        expect(model.selected_values).to eq('f|t')
      end
    end
  end

  describe "#group_params" do
    describe ":and" do
      before(:each) do
        expect(model).to receive(:operator) { ',' }
      end

      it "returns empty string when no key exists" do
        expect(search).to receive(:search_params) { {} }
        expect(model.group_params).to eq([])
      end
      it "fetches the groups key" do
        expect(search).to receive(:search_params) { {hd: '1,3', another: '2'} }
        expect(model.group_params).to eq(['1','3'])
      end
    end
    describe ":or" do
      before(:each) do
        expect(model).to receive(:operator) { '|' }
      end

      it "returns empty string when no key exists" do
        expect(search).to receive(:search_params) { {} }
        expect(model.group_params).to eq([])
      end
      it "fetches the groups key" do
        expect(search).to receive(:search_params) { {hd: '1|3', another: '2'} }
        expect(model.group_params).to eq(['1','3'])
      end
    end
  end

  describe "#group_params_string" do
    it "returns empty string when no key exists" do
      expect(search).to receive(:search_params) { {} }
      expect(model.group_params_string).to eq('')
    end
    it "fetches the groups key" do
      expect(search).to receive(:search_params) { {hd: '1', another: '2'} }
      expect(model.group_params_string).to eq('1')
    end
  end

  describe "#type" do
    it "returns the class_facets's #type" do
      expect(search).to receive(:class_facets) { {hd: {type: 'exclusive_or'}} }
      expect(model.type).to eq('exclusive_or')
    end
    it "returns nil if raised" do
      expect(search).to receive(:class_facets) { raise "Boom!" }
      expect(model.type).to be_nil
    end
  end

  describe "#operator" do
    it "returns nil with a bad key" do
      expect(model).to receive(:operator_for) { }
      expect(model.operator).to be_nil
    end
    it "returns , for :and" do
      expect(model).to receive(:operator_for) { :and }
      expect(model.operator).to eq(',')
    end
    it "returns | for :or" do
      expect(model).to receive(:operator_for) { :or }
      expect(model.operator).to eq('|')
    end
  end

  describe "#build_items" do
    it "is private" do
      expect {
        model.build_items
      }.to raise_error(NoMethodError)
    end
    it "returns a group of FacetItems" do
      expect(model.send(:build_items).all?{|x| x.is_a?(Elasticsearch::FacetedSearch::FacetItem)}).to eq(true)
    end
  end

  describe "#terms_collection" do
    it "is private" do
      expect {
        model.terms_collection
      }.to raise_error(NoMethodError)
    end
    it "returns mapped_objects if search does not respond to 'key'_collection?" do
      expect(model).to receive(:mapped_objects) { 'hi' }
      expect(model.send(:terms_collection)).to eq('hi')
    end
    it "returns collection from facet" do
      expect(search).to receive(:hd_collection) { [{id: 1}, {id: 2}] }
      expect(model.send(:terms_collection)).to eq([{id: 1}, {id: 2}])
    end
  end

  describe "#hit_count_mapping" do
    before(:each) do
      @items = [{"term"=>"t", "count"=>476}, {"term"=>"f", "count"=>5}, {"term"=>"F", "count"=>476}]
    end
    it "is private" do
      expect {
        model.hit_count_mapping(@items)
      }.to raise_error(NoMethodError)
    end
    it "returns merged hashes" do
      expect(model.send(:hit_count_mapping, @items)).to eq({"t"=>476, "f"=>481})
    end
  end
end
