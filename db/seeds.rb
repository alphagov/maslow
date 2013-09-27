# Create a default user for GDS::SSO running in development mode

@user = User.new(name: "Winston Smith-Churchill", email: "winston@alphagov.co.uk")
@user.permissions = ["signin"]
@user.save!
