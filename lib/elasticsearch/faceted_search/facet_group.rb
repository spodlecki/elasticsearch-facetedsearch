require 'forwardable'

module Elasticsearch
  module FacetedSearch
    class FacetGroup
      extend Forwardable

      OPERATOR_MAPPING = {
        :and => ',',
        :or => '|'
      }

      attr_accessor :search, :objects, :key

      def_delegators :search, :class_facets, :execution_type, :search_params
      # delegate :class_facets, :execution_type, :search_params, to: :search

      def initialize(search, key, objects)
        self.search = search
        self.key = key.to_sym
        self.objects = hit_count_mapping(objects['terms'])
      end

      def items
        @items ||= build_items
      end

      def title
        class_facets[key][:title]
      rescue
        key.to_s.humanize
      end

      def selected_values
        v = search_params.fetch(key, '')
        operator ? v.split(operator).map(&:downcase) : v.downcase
      end

      def group_params
        group_params_string.split(operator).dup
      end

      def group_params_string
        search_params.fetch(key, '')
      end

      def type
        class_facets[key][:type]
      rescue
        nil
      end

      # Returns the string value ',' or '|'
      #
      def operator
        @operator ||= operator_mappings(operator_for)
      end

      def operator_mappings(i=nil)
        OPERATOR_MAPPING.fetch(i, nil)
      end

    private

      def operator_for
        execution_type(
          class_facets[key][:type]
        )
      end

      def build_items
        terms_collection.map do |x|
          FacetItem.new(self, x.merge(count: count(x[:id])))
        end
      end

      def terms_collection
        return mapped_objects unless search.respond_to?(:"#{key}_collection")
        @terms_collection ||= search.public_send(:"#{key}_collection")
      end

      # Occationally ElasticSearch will return boolean facets with mix cased characters (T/t & F/f)
      # This method cleans this result and combines the counts to be correct & valid
      #
      def hit_count_mapping(o)
        @hit_count_mapping ||= o.each_with_object(Hash.new(0)) do |result, hash|
          term = result['term'].to_s.downcase
          hash[term] += result['count']
        end
      end

      def count(id)
        objects.fetch(id.to_s.downcase, 0)
      end

      def mapped_objects
        objects.map{|k,v| {id: k, term: k, count: v} }
      end
    end
  end
end