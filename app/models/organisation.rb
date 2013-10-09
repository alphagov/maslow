require 'gds_api/need_api'

class Organisation
  cattr_writer :organisations

  attr_reader :id, :name

  def initialize(atts)
    @id = atts[:id]
    @name = atts[:name]
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
