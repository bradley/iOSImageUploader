ImageServer::Application.routes.draw do
  scope :format => true, :constraints => { :format => 'json' } do
    resources :photos
    root :to => 'photos#index'
  end
end
