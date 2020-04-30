require "gds-sso/user"
require "ability"

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
  field "organisation_content_id", type: String
  field "bookmarks", type: Array, default: []
  field "disabled", type: Boolean, default: false

  delegate :can?, :cannot?, to: :ability

  def ability
    @ability ||= Ability.new(self)
  end

  def self.find_by_uid(uid)
    find_by(uid: uid)
  end

  def viewer?
    has_permission?("signin")
  end

  def editor?
    has_permission?("editor") || admin?
  end

  def admin?
    viewer? && has_permission?("admin")
  end

  def toggle_bookmark(content_id)
    if bookmarks.include?(content_id)
      bookmarks.delete(content_id)
    else
      bookmarks << content_id
    end
  end
end
