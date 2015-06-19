# Elasticsearch::FacetedSearch

[![Code Climate](https://codeclimate.com/github/spodlecki/elasticsearch-facetedsearch/badges/gpa.svg)](https://codeclimate.com/github/spodlecki/elasticsearch-facetedsearch)
[![Test Coverage](https://codeclimate.com/github/spodlecki/elasticsearch-facetedsearch/badges/coverage.svg)](https://codeclimate.com/github/spodlecki/elasticsearch-facetedsearch/coverage)

Quickly add faceted searching to your Rails app. This gem is opinionated as to how faceted searching works. **Filters are applied to the counts** so the counts themselves will change while different filters are applied.

## Installation

Add this line to your application's Gemfile:

    gem 'elasticsearch-facetedsearch'

And then execute:

    $ bundle

Create `config/initializers/elasticsearch.rb`. We normally namespace our indexed like below.

    ELASTICSEARCH_INDEX = [
      Rails.env.development? && `whoami`.strip,
      Rails.env,
      Rails.application.class.to_s.split("::").first.downcase
    ].reject(&:blank?).join('_')

    # Optional concepts to help with indexing / connection
    ELASTICSEARCH_MODELS = []
    ELASTICSEARCH_SERVER = 'http://lalaland.com:9200'

    Elasticsearch::Model.client = Elasticsearch::Client.new({
      log: false,
      host: ELASTICSEARCH_SERVER,
      retry_on_failure: 5,
      reload_connections: true
    })

## Dependencies

- [Elasticsearch::Model](https://github.com/elastic/elasticsearch-rails/tree/master/elasticsearch-model)
- [Rails > 3.2.8](http://rubyonrails.org/)
- [Elasticsearch Server > 1.0.1](http://www.elastic.co)

## Usage

### Controller

    # Good idea to prefilter the params with strong_params
    #
    def search
      @search = FruitFacetsSearch.new(params)

      # Fetch results
      # @search.results

      # Fetch facets
      # @search.facets
    end

### Facet Search Class

    class FruitFacetsSearch
      include Elasticsearch::FacetedSearch::FacetBase

      # ... include other facet classes (examples below) ...
      include Elasticsearch::FacetedSearch::FacetColor

      # *required
      # The type to search for (Elasticsearch Type)
      # Can be an Array or String
      def type
        'fruit'
      end

      # Use this to add a query search or something
      # Probably best to cache the results
      def query
        @query ||= super
      end

      # Apply additional pre-filters
      # If overwriting this method, ensure to call super, and ensure to cache the results
      # => require color to be 'blue'
      def filter_query
        @filter_query ||= begin
          fq = super
          fq << { term: { color: 'blue' } }
          fq
        end
      end

      # Force specific limit or allow changable #s
      #
      def limit
        33
      end

      # Whitelisted collection of sortable options
      def sorts
        [
          {
            label: "Relevant",
            value: "relevant",
            search: [
              "_score"
            ],
            default: true
          }
        ]
      end

      # Want to always keep facet counts the same regardless of filters applied?
      # pass true to keep counts scoped to search, & false to remove filters entirely
      #
      def build_facets
        super(false)
      end
    end

### Facet Creation Class

    module Elasticsearch
      module FacetedSearch
        module FacetColor
          extend ActiveSupport::Concern

          included do
            # Adds the facet to the class.facets collection
            #
            # Available types:
            # => facet_multivalue
            # => facet_multivalue_and(:ident, 'elasticsearch_field', 'Human String')
            #     - Allows multiple values, but filters with :and execution
            # => facet_multivalue_or(:ident, 'elasticsearch_field', 'Human String')
            #     - Allows multiple values, but filters with :or execution
            # => facet_exclusive_or(:ident, 'elasticsearch_field', 'Human String')
            #     - Allows single value only
            #
            facet_multivalue_or(:color, 'color_field', 'Skin Color')
          end

          # *required
          # Should we apply the filter for this facet?
          # __Replace 'color' with the :ident value of your facet key
          def filter_color?
            valid_color?
          end

          # *required
          # Returns the array of selected values
          # __Replace 'color' with the :ident value of your facet key
          # __You should really take this time to whitelist the values and remove any noise. Elasticsearch can be picky if you're searching a number field and pass it an alpha character
          def color_value
            return unless valid_color?
            search_params[:color].split( operator_for(:color) )
          end

          # (optional)
          # By default, Elasticsearch only returns terms that are pertaining to the specific search. If a result was filtered out, that term would not show up.
          # Normally this isn't optimal... create this method and return an array of hashes with id and term keys.
          #
          # __Replace 'color' with the :ident value of your facet key
          def color_collection
            @color_collection ||= begin
              Color.all.map{|x| {id: x.id, term: x.name}}
            end
          end

          # (concept)
          # Use these type of helper methods to validate the information given to you by users
          #
          def valid_color?
            search_params[:color].present? && !!(search_params[:color] =~ /[\|[0-9]+]/)
          end
        end
      end
    end

### Using Sortable

The only requirement to change sort options is to apply a `:sort` http param

### Pagniation

Pagination is supported, but only tested with Kaminari.

### HTML

**Facets**

    %ul
      -@search.facets.each do |group|
        %li.title=group.title
        -group.items.each do |item|
          - # Assuming you have some dynamic urls, you can use the url_for and merge in the params
          %li=item.link_to("#{item.term} (#{item.count})", url_for(params.merge(item.params_for)))

**Results**

    %ul
      -@search.results.each do |item|
        - # item is now direct reference to the elastic search _source
        - # item also contains item._type that displays the Elasticsearch type field
        %li=item.id

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## TODO

- Setup Code Climate
- Setup CI
- Setup facet generator