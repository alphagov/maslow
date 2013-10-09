require 'gds_api/need_api'
require 'plek'
require 'json'

class NeedsController < ApplicationController

  NEED_API = GdsApi::NeedApi.new(Plek.current.find('needapi'))

  JUSTIFICATIONS = [
    "it's something only government does",
    "the government is legally obliged to provide it",
    "it's inherent to a person's or an organisation's rights and obligations",
    "it's something that people can do or it's something people need to know before they can do something that's regulated by/related to government",
    "there is clear demand for it from users",
    "it's something the government provides/does/pays for",
    "it's straightforward advice that helps people to comply with their statutory obligations"
  ]
  IMPACT = [
    "Endangers the health of individuals",
    "Has serious consequences for the day-to-day lives of your users",
    "Annoys the majority of your users. May incur fines",
    "Noticed by the average member of the public",
    "Noticed by an expert audience",
    "No impact"
  ]

  def need_api_submitter
    NEED_API
  end

  def index
  end

  def new
    @need = Need.new({})
    @justifications = JUSTIFICATIONS
    @impact = IMPACT
    @organisations = Organisation.all
  end

  def create
    # Rails inserts an empty string into multi-valued fields.
    # We are removing the unneeded value
    if params["need"]
      if params["need"]["justifications"]
        params["need"]["justifications"].select!(&:present?)
      end
      if params["need"]["organisation_ids"]
        params["need"]["organisation_ids"].select!(&:present?)
      end
      if params["need"]["met_when"]
        params["need"]["met_when"] = params["need"]["met_when"].split("\n").map(&:strip)
      end
    else
      raise(ArgumentError, "Need data not found")
    end
    @need = Need.new(params["need"])

    if @need.valid?
      need_api_submitter.create_need(@need)
      redirect_to("/")
    else
      @justifications = JUSTIFICATIONS
      @impact = IMPACT
      @organisations = Organisation.all
      @need.met_when = @need.met_when.try do |f|
        f.join("\n")
      end
      render "new", :status => :unprocessable_entity
    end
  end

end
