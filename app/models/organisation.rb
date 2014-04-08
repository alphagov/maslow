require 'gds_api/need_api'

class Organisation
  cattr_writer :organisations

  attr_reader :id, :name, :abbreviation, :status

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
    @@organisations ||= self.load_organisations
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
