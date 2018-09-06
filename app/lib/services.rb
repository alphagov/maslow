require 'gds_api/support'
require 'gds_api/publishing_api_v2'

module Services
  def self.publishing_api_v2
    @publishing_api_v2 ||= GdsApi::PublishingApiV2.new(
      Plek.current.find('publishing-api'),
      bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example'
    )
  end

  def self.support
    @support ||= GdsApi::Support.new(Plek.current.find('support'))
  end
end
