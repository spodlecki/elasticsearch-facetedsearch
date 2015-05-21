require 'forwardable'

module Elasticsearch
  module FacetedSearch
    class FacetItem
      extend Forwardable

      attr_accessor :group, :object

      def_delegators :group, :operator_mappings, :operator, :key, :selected_values, :group_params, :type
      def_delegators :object, :term, :count
      # delegate :operator_mappings, :operator, :key, :selected_values, :group_params, :type, to: :group
      # delegate :term, :count, to: :object

      def id
        object.id.to_s
      end

      def initialize(group, object)
        self.group = group
        self.object = OpenStruct.new(object)
      end

      def selected?
        @selected ||= Array(group_params).include?(id)
      end

      def params_for
        if selected?
          case type
          when 'multivalue' then remove_multivalue
          when 'multivalue_and' then remove_multivalue(:and)
          when 'multivalue_or'  then remove_multivalue(:or)
          when 'exclusive_or'   then remove_singlevalue
          # else                  raise UnknownSelectableType.new "Unknown selectable type for #{param_key} in #{group.type}"
          end
        else
          case type
          when 'multivalue'     then add_multivalue
          when 'multivalue_and' then add_multivalue(:and)
          when 'multivalue_or'  then add_multivalue(:or)
          when 'exclusive_or'   then add_singlevalue
          # else                  raise UnknownSelectableType.new "Unknown selectable type #{selectable_type} for #{@type}"
          end
        end
      end

    private
      def params
        @params ||= group_params.dup
      end

      # Removing a value from the parameters
      # Example:
      #   group_params = ['1','3','4']
      #   id = 3
      # => {key => '1|4'}
      def remove_multivalue(op=nil)
        op = operator_mappings(op) || operator
        p = params.reject{|v| matches?(v) }

        if p.blank?
          remove_singlevalue
        else
          {
            key => p.reject(&:blank?)
                         .join( op )
          }
        end
      end

      # Remove a single value from params
      #
      def remove_singlevalue
        {
          key => nil
        }
      end

      # Adding a value to the parameters
      # Example:
      #   group_params = ['1','3','4']
      #   id = 5
      # => {key => '1|3|4|5'}
      def add_multivalue(op=nil)
        op = operator_mappings(op) || operator

        if params.blank?
          add_singlevalue
        else
          {
            key => (Array(params) + Array(id.to_s)).uniq
                                     .join( op )
          }
        end
      end

      # Adding a single value to the parameters
      # Example:
      #   group_params = ['7']
      #   id = 5
      # => {key => '5'}
      def add_singlevalue
        { key => id.to_s }
      end

      def matches?(v)
        v.to_s == id.to_s
      end

    end
  end
end