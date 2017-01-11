require 'gds_api/need_api'
require 'gds_api/organisations'

class Organisation
  attr_reader :id, :content_id, :name, :abbreviation, :status

  def self.cache
    @cache ||= LRUCache.new(ttl: 1.hour)
  end

  def self.reset_cache
    @cache = nil
  end

  def initialize(atts)
    @id = atts[:details][:slug]
    @content_id = atts[:content_id]
    @name = atts[:title]
    @abbreviation = atts[:details][:abbreviation]
    @status = atts[:details][:govuk_status]
  end

  def to_option
    [name_with_abbreviation_and_status, id]
  end

  def name_with_abbreviation_and_status
    if abbreviation.present? && abbreviation != name
      # Use square brackets around the abbreviation
      # as Chosen doesn't like matching with
      # parentheses at the start of a word
      "#{name} [#{abbreviation}] (#{status})"
    else
      "#{name} (#{status})"
    end
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
    (organisations || []).map {|atts|
      self.new(atts.deep_symbolize_keys)
    }
  end

  def self.organisations
    GdsApi::Organisations.new(Plek.current.find('whitehall-admin')).organisations.with_subsequent_pages.to_a
  end
end
