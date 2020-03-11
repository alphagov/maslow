# Create a default user for GDS::SSO running in development mode

unless User.where(permissions: "signin").exists?
  @user = User.new(name: "Winston Smith-Churchill", email: "winston@alphagov.co.uk")
  @user.permissions = %w[signin]
  @user.save!
end
