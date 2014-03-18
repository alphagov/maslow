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
  field "organisation_slug", type: String

  attr_accessible :email, :name, :uid, :version, :organisation_slug

  def self.find_by_uid(uid)
    where(uid: uid).first
  end

  def viewer?
    has_permission?('signin')
  end

  def editor?
    has_permission?('editor') || admin?
  end

  def admin?
    viewer? && has_permission?('admin')
  end
end
