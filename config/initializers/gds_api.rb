require 'gds_api/need_api'
require 'gds_api/content_api'
require 'gds_api/support'

Maslow.need_api = GdsApi::NeedApi.new(Plek.current.find('need-api'),
                                      API_CLIENT_CREDENTIALS[:need_api])

Maslow.content_api = GdsApi::ContentApi.new(Plek.current.find('contentapi'),
                                            API_CLIENT_CREDENTIALS[:content_api])

Maslow.support_api = GdsApi::Support.new(Plek.current.find('support'),
                                         API_CLIENT_CREDENTIALS[:support])
