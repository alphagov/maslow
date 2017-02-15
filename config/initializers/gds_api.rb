require 'gds_api/support'
require 'gds_api/publishing_api_v2'

Maslow.publishing_api_v2 = GdsApi::PublishingApiV2.new(
  Plek.current.find('publishing-api'),
  bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] || 'example'
)

Maslow.support_api = GdsApi::Support.new(Plek.current.find('support'),
                                         API_CLIENT_CREDENTIALS[:support])
