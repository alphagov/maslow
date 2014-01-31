Maslow::Application.routes.draw do

  get "/healthcheck" => Proc.new { [200, {"Content-type" => "text/plain"}, ["OK"]] }

  get :maslow_need_bookmarklet, controller: :maslow_need_bookmarklet, path: 'maslow-need-bookmarklet'

  resources :needs, except: [:destroy], constraints: { id: /[0-9]+/ } do
    member do
      get :revisions
      put :descope
      put :closed
      get :out_of_scope, path: 'out-of-scope'
      delete :closed, to: 'needs#reopen', as: :reopen
    end
  end

  root :to => redirect('/needs')
end
