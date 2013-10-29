Maslow::Application.routes.draw do

  get "/healthcheck" => Proc.new { [200, {"Content-type" => "text/plain"}, ["OK"]] }

  resources :needs,
            except: [:destroy],
            constraints: { id: /[0-9]+/ }

  root :to => redirect('/needs')

end
