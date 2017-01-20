Rails.application.routes.draw do
  mount GovukAdminTemplate::Engine, at: '/style-guide'

  get "/healthcheck" => Proc.new { [200, { "Content-type" => "text/plain" }, ["OK"]] }

  get :bookmarklet, controller: :bookmarklet, path: 'bookmarklet'

  resources :bookmarks, only: [:index] do
    collection do
      post :toggle
    end
  end

  resources :notes, only: [:create]

  resources :needs, except: [:destroy], param: :content_id do
    member do
      get :revisions
      get :status
      patch :status, to: 'needs#update_status', as: 'update_status'
      post :closed
      post :reopen
      get :actions
    end
  end

  root to: redirect('/needs')
end
