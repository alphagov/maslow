Maslow::Application.routes.draw do

  root :to => "default#index"
  resources :needs, only: [:index, :new]

end
