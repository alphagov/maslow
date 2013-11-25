require 'gds_api/need_api'
require 'gds_api/content_api'

Maslow.need_api = GdsApi::NeedApi.new(Plek.current.find('need-api'), API_CLIENT_CREDENTIALS)
Maslow.content_api = GdsApi::ContentApi.new(Plek.current.find('contentapi'), API_CLIENT_CREDENTIALS)
