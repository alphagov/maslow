Maslow::Application.routes.draw do

  get "/healthcheck" => Proc.new { [200, {"Content-type" => "text/plain"}, ["OK"]] }

  get "needs/export", to: "needs#export"
  resources :needs, except: [:destroy], constraints: { id: /[0-9]+/ } do
    member do
      get :revisions
      put :descope
      put :closed
    end
  end


  root :to => redirect('/needs')

end
