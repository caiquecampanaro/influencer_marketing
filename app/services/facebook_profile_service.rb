class FacebookAuthService
    require 'httparty'
  
    BASE_URL = 'https://graph.facebook.com/v22.0'
  
    def get_access_token(code, redirect_uri)
      response = HTTParty.get("#{BASE_URL}/oauth/access_token", {
        query: {
          client_id: ENV['FACEBOOK_APP_ID'],
          redirect_uri: redirect_uri,
          client_secret: ENV['FACEBOOK_APP_SECRET'],
          code: code
        }
      })
  
      handle_response(response)
    end
  
    def get_user_info(access_token)
      response = HTTParty.get("#{BASE_URL}/me", {
        query: {
          fields: 'id,name,email',
          access_token: access_token
        }
      })
  
      handle_response(response)
    end
  
    private
  
    def handle_response(response)
      if response.success?
        response.parsed_response
      else
        error = response.parsed_response['error'] || {}
        raise "Erro Facebook (#{error['code']}): #{error['message']}"
      end
    end
  end