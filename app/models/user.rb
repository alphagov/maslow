require "gds-sso/user"

class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include GDS::SSO::User

  field "name",    type: String
  field "uid",     type: String
  field "version", type: Integer
  field "email",   type: String
  field "permissions", type: Array
  field "remotely_signed_out", type: Boolean, default: false

  attr_accessible :email, :name, :uid, :version
  attr_accessible :uid, :email, :name, :permissions, as: :oauth

  def self.find_by_uid(uid)
    where(uid: uid).first
  end
end
