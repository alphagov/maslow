Maslow::Application.routes.draw do
  mount GovukAdminTemplate::Engine, at: '/style-guide'

  get "/healthcheck" => Proc.new { [200, {"Content-type" => "text/plain"}, ["OK"]] }

  get :bookmarklet, controller: :bookmarklet, path: 'bookmarklet'

  resources :bookmarks, only: [:index] do
    collection do
      post :toggle
    end
  end

  resources :notes, only: [:create]

  resources :needs, except: [:destroy], constraints: { id: /[0-9]+/ } do
    member do
      get :revisions
      put :descope
      put :closed
      get :out_of_scope, path: 'out-of-scope'
      delete :closed, to: 'needs#reopen', as: :reopen
      get :actions
      get :close_as_duplicate, path: 'close-as-duplicate'
    end
  end

  root :to => redirect('/needs')
end
