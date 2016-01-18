module Elasticsearch
  module FacetedSearch
    module Pagination
      def total_count
        search['hits']['total'].to_i
      rescue
        0
      end

      def total_pages
        (total_count.to_f / limit_value.to_f).ceil
      end

      def limit_value
        limit
      end

      def limit
        (search_params[:limit] ||= 32).to_i
      end

      def current_page
        (search_params[:page] ||= 1).to_i
      end
    end
  end
end