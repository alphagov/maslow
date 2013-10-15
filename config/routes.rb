Maslow::Application.routes.draw do

  get "/healthcheck" => Proc.new { [200, {"Content-type" => "text/plain"}, ["OK"]] }

  resources :needs, only: [:index, :new, :create]

  root :to => redirect('/needs')

end
