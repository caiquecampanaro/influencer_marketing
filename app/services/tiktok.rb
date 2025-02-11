require 'faraday'
require 'json'

class TikTok
  CLIENT_KEY = 'sbawualtc227t17bl4'
  CLIENT_SECRET = 'QDDbiHtTVWlU8kQWHQbuj6R3qOdOgGqD'
  REDIRECT_URI = 'http://localhost:3000/auth/callback'

  class << self
    # Passo 1: Trocar o código de autorização pelo access token
    def get_access_token(code)
      conn = Faraday.new do |f|
        f.request :url_encoded  # Automatically sets Content-Type: application/x-www-form-urlencoded
      end

      response = conn.post('https://open.tiktokapis.com/v2/oauth/token/') do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.headers['Cache-Control'] = 'no-cache'
        req.body = URI.encode_www_form({
          client_key: CLIENT_KEY,
          client_secret: CLIENT_SECRET,
          code: code,
          grant_type: 'authorization_code',
          redirect_uri: REDIRECT_URI
        })
      end

      parsed_response = JSON.parse(response.body)

      if response.status == 200
        {
          access_token: parsed_response['access_token'],
          refresh_token: parsed_response['refresh_token'],
          open_id: parsed_response['open_id'],
          expires_in: parsed_response['expires_in'],
          refresh_expires_in: parsed_response['refresh_expires_in'],
          scope: parsed_response['scope']
        }
      else
        {
          error: parsed_response['error'],
          error_description: parsed_response['error_description'],
          log_id: parsed_response['log_id']
        }
      end
    end

    # Passo 2: Usar o access token para obter os dados do criador
    def get_creator_data(access_token)
      conn = Faraday.new do |f|
        f.request :json
        f.response :json
      end

      response = conn.get('https://open.tiktokapis.com/v2/creator/data') do |req|
        req.headers['Authorization'] = "Bearer #{access_token}"
      end

      if response.status == 200
        response.body['data']
      else
        {
          error: response.body['error'],
          message: response.body['message'],
          log_id: response.body['log_id']
        }
      end
    end
  end
end
