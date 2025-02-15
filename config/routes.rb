Rails.application.routes.draw do
  get '/auth/tiktok', to: 'auth#tiktok'
  get '/auth/callback', to: 'auth#callback'
  get '/auth/success', to: 'auth#success'
  get 'videos/list', to: 'auth#list_videos'
  get '/auth/test_creator/:username', to: 'auth#test_creator_data'
  get '/callback/tiktok*.txt', to: 'application#serve_verification_file'
  get '/callback/tiktokRSGCQZexU2B8BHfz106Cmy76m3cJK20W.txt', to: 'application#serve_verification_file'
  get '/auth/facebook', to: 'auth#facebook_login'
  get '/auth/facebook/callback', to: 'auth#facebook_callback'
  get '/auth/youtube', to: 'auth#youtube_authorize', as: :youtube_auth
  get '/auth/youtube/callback', to: 'auth#youtube_callback'
end
