require 'gds_api/need_api'

Maslow.need_api = GdsApi::NeedApi.new(Plek.current.find('needapi'))
