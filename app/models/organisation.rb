require 'gds_api/need_api'
require 'gds_api/organisations'

class Organisation
  attr_reader :content_id, :title, :internal_name, :publication_state, :base_path

  def self.cache
    @cache ||= LRUCache.new(ttl: 1.hour)
  end

  def self.reset_cache
    @cache = nil
  end

  def initialize(atts)
    @content_id = atts[:content_id]
    @title = atts[:title]
    @internal_name = atts[:internal_name]
    @publication_state = atts[:publication_state]
    @base_path = atts[:publication_state]
  end

  def to_option
    [title_and_publication_state, content_id]
  end

  def title_and_publication_state
    suffix = (publication_state == "draft" ? " (draft)" : "")
    "#{title}#{suffix}"
  end

  def self.to_options
    all.map(&:to_option)
  end

  def self.all
    cache.fetch('all_organisations') do
      # gds-api-adapters would cache the HTTP response for us if cache headers
      # were set, but it wouldn't be at all obvious to readers of this code and
      # we'd still have parse the JSON and convert into our Organisation models.
      # Even if they were set now, cache headers might get changed in the future
      # and ruin our performance.
      load_organisations
    end
  end

  private
  def self.load_organisations
    (organisations || []).map { |atts|
      new(atts.deep_symbolize_keys)
    }
  end

  def self.organisations
    Maslow.publishing_api_v2.get_linkables(document_type: "organisation")
  end
end
