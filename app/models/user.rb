require "gds-sso/user"
require 'ability'

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
  field "bookmarks", type: Array, default: Array.new

  attr_accessible :email, :name, :uid, :version, :organisation_slug

  delegate :can?, :cannot?, :to => :ability

  def ability
    @ability ||= Ability.new(self)
  end

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

  def toggle_bookmark(need_id)
    if bookmarks.include?(need_id)
      bookmarks.delete(need_id)
    else
      bookmarks << need_id
    end
  end
end
