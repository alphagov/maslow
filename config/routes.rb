Rails.application.routes.draw do
  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::Mongoid,
  )

  resources :bookmarks, only: [:index], param: :content_id do
    collection do
      post :toggle
    end
  end

  resources :notes, only: [:create]

  resources :needs, except: [:destroy], param: :content_id do
    member do
      get :revisions
      get :actions
      post :actions
    end
  end

  root to: redirect("/needs")
end
