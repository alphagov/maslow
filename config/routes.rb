Rails.application.routes.draw do
  mount GovukAdminTemplate::Engine, at: '/style-guide'

  get "/healthcheck" => Proc.new { [200, { "Content-type" => "text/plain" }, ["OK"]] }

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
      post :publish
      post :discard
      post :unpublish
    end
  end

  root to: redirect('/needs')
end
