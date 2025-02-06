Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'sync', to: 'influencers#sync'
    end
  end
end
