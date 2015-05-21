module Elasticsearch
  module FacetedSearch
    module Sortable

      # Setup by the parent class
      # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-sort.html
      #
      # => returns Array or Hash
      # {
      #   label: "Relevant",
      #   value: "relevant",
      #   search: {...sort value(s) for elasticsearch...},
      #   default: false
      # }
      #
      def sorts
        []
      end

      # Returns current sort hash to use for elasticsearch query
      #
      def current_sort_for_search
        return unless current_sort.present?
        current_sort[:search]
      end

      # Returns entire sort hash (Label, value, search....)
      #
      def current_sort
        sorts.select{|x| x.fetch(:value) == selected_sort_value }.first || default_sort
      end

    private

      # Selected sort value (params || default)
      # => returns String
      def selected_sort_value
        sort_param.present? ? sort_param : default_sort_value
      end

      # Returns string for sort param even if invalid
      # rescue required if search params is not a hash
      #
      def sort_param
        search_params[:sort]
      rescue
        nil
      end

      # Returns string value of the default sort signified by
      # => default: true
      def default_sort_value
        default_sort.fetch(:value, nil)
      end

      # Returns entire hash for sort for the default
      def default_sort
        sorts.select{|x| x.fetch(:default, false) }.first
      end
    end
  end
end