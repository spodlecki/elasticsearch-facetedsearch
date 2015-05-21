require 'ostruct'
require 'elasticsearch/model'

module Elasticsearch
  module FacetedSearch
    module FacetBase
      include Pagination
      include Sortable

      extend ActiveSupport::Concern

      included do
        extend ClassMethods
        attr_accessor :params

        def initialize(p)
          self.params = p
        end

        def results
          @results ||= search['hits']['hits'].map{|x| Hashie::Mash.new(x['_source'].merge('_type' => x['_type'])) }
        end

        def facets
          @facets ||= search['facets'].map{|key, values| FacetGroup.new(self, key, values) }
        end

        def search
          @search ||= Elasticsearch::Model.client.search({
                index: ELASTICSEARCH_INDEX,
                type: type,
                body: query
              })
        end
      end

      ## self <<
      module ClassMethods

        def facets
          @facets || []
        end

        def facet(name, field, type, title)
          @facets ||= {}
          @facets.merge!({
            name.to_sym => {
              field: field,
              type: type,
              title: title
            }
          })
        end

        def facet_multivalue(name, field, title = nil)
          facet(name, field, 'multivalue', title)
        end

        def facet_multivalue_and(name, field, title = nil)
          facet(name, field, 'multivalue_and', title)
        end

        def facet_multivalue_or(name, field, title = nil)
          facet(name, field, 'multivalue_or', title)
        end

        def facet_exclusive_or(name, field, title = nil)
          facet(name, field, 'exclusive_or', title)
        end
      end
      # / self

      ##############
      # Instance
      #
      def class_facets
        self.class.facets.dup
      end

      def query
        q = {
          size: limit,
          from: ([current_page.to_i, 1].max - 1) * limit,
          sort: current_sort_for_search
        }

        # Filters
        q.merge!({
          :filter => {
            :and => filter_query
          }
        }) unless filter_query.blank?

        # Facets
        q.merge!({
          :facets => facet_query
        }) unless facet_query.blank?

        q.reject{|k,v| v.blank? }
      end

      def facet_query
        @facet_query ||= build_facets
      end

      def filter_query
        @filter_query ||= build_filters
      end

      def search_params
        params
      end

    protected

      def operator_mappings(i=nil)
        FacetGroup::OPERATOR_MAPPING.fetch(i, nil)
      end

      def operator_for(key)
        operator_mappings(
          execution_type(
            class_facets[key][:type]
          )
        )
      end

      def execution_type(type)
        case type
          when 'multivalue'
            # TODO: Based off params
          when 'multivalue_or'
            :or
          when 'multivalue_and'
            :and
          when 'exclusive_or'
            nil
        end
      end

      def facet_size_allowed
        70
      end

    private

      def build_facets(filter_counts=true)
        h = {}
        filtered_facets = filter_counts && filter_query.present? ? {facet_filter: { :and => filter_query }} : {}

        class_facets.each do |k,v|
          h.merge!({
            k => {
              terms: {
                field: v[:field],
                size: facet_size_allowed
              }.merge(filtered_facets)
            }.reject{|k,v| v.blank?}
          })
        end

        h
      end

      # Whitelist and filter
      def build_filters
        class_facets.map do |type, info|
          if respond_to?(:"filter_#{type}?") and public_send("filter_#{type}?")
            {
              terms: {
                info[:field] => values_for(type),
                :execution => execution_type(info[:type])
              }.reject{|k,v| v.blank?}
            }
          end
        end.compact
      end

      def values_for(facet_type)
        Array(public_send("#{facet_type}_value"))
      end
    end
  end
end