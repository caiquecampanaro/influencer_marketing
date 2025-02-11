Rails.application.routes.draw do
  get '/auth/tiktok', to: 'auth#tiktok'
  get '/auth/callback', to: 'auth#callback'
  get '/auth/test_creator/:username', to: 'auth#test_creator_data'
  get '/callback/tiktok*.txt', to: 'application#serve_verification_file'
  get '/callback/tiktokETtTSguI5Nu5gFu5UV2d7ZcFJTQR99xE.txt', to: 'application#serve_verification_file'
end
