class Note
  include Mongoid::Document
  include Mongoid::Timestamps

  field :text, type: String
  field :need_id, type: Integer
  field :author, type: Hash
  field :revision, type: String
  field :content_id, type: String

  default_scope -> { order_by(:created_at.desc) }

  validates_presence_of :text, :need_id, :content_id, :author
end
