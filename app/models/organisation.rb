require 'gds_api/need_api'

class Organisation
  attr_reader :id, :name, :abbreviation, :status

  def self.cache
    @cache ||= LRUCache.new(ttl: 1.hour)
  end

  def self.reset_cache
    @cache = nil
  end

  def initialize(atts)
    @id = atts[:id]
    @name = atts[:name]
    @abbreviation = atts[:abbreviation]
    @status = atts[:govuk_status]
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
    (need_api.organisations || []).map {|atts|
      self.new(atts.symbolize_keys)
    }
  end

  def self.need_api
    Maslow.need_api
  end
end
