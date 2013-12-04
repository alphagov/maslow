require 'gds_api/need_api'

class Organisation
  cattr_writer :organisations

  attr_reader :id, :name, :abbreviation

  def initialize(atts)
    @id = atts[:id]
    @name = atts[:name]
    @abbreviation = atts[:abbreviation]
  end

  def display_name
    if abbreviation.present? && abbreviation != name
      # Use square brackets around the abbreviation
      # as Chosen doesn't like matching with
      # parentheses at the start of a word
      "#{name} [#{abbreviation}]"
    else
      name
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
