Maslow::Application.routes.draw do

  root :to => redirect('/needs')
  resources :needs, only: [:index, :new, :create]

end
