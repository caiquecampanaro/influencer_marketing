Rails.application.routes.draw do
  get '/auth/tiktok', to: 'auth#tiktok'
  get '/auth/callback', to: 'auth#callback'
  get '/auth/success', to: 'auth#success'
  get 'videos/list', to: 'auth#list_videos'
  get '/auth/test_creator/:username', to: 'auth#test_creator_data'
  get '/callback/tiktok*.txt', to: 'application#serve_verification_file'
  get '/callback/tiktok881RKSuVOc4TOm97Z5HQBPLtFskXOZlI.txt', to: 'application#serve_verification_file'
  get '/auth/facebook', to: 'auth#facebook_login'
  get '/auth/facebook/callback', to: 'auth#facebook_callback'
end
