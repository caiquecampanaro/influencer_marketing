require 'faraday'
require 'json'

class TikTok
  # Constantes para configuração do TikTok
  CLIENT_KEY = 'sbawualtc227t17bl4'
  CLIENT_SECRET = 'QDDbiHtTVWlU8kQWHQbuj6R3qOdOgGqD'
  
  # Método para definir o redirect URI
  def self.redirect_uri
    # Definir redirect URI de forma mais explícita
    ngrok_base = '5638-2804-d4b-94d3-2a00-9d95-aa9c-9f09-e8e0.ngrok-free.app'
    "https://#{ngrok_base}/auth/callback"
  end

  # Definir REDIRECT_URI usando o método de classe
  REDIRECT_URI = redirect_uri

  class << self
    # Passo 1: Trocar o código de autorização pelo access token
    def get_access_token(code, code_verifier)
      # Passo 1: Trocar o código de autorização pelo access token
      token_url = 'https://open.tiktokapis.com/v2/oauth/token/'
      
      body_params = {
        client_key: CLIENT_KEY,
        client_secret: CLIENT_SECRET,
        code: code,
        grant_type: 'authorization_code',
        redirect_uri: REDIRECT_URI,
        code_verifier: code_verifier
      }

      Rails.logger.debug("Parâmetros de token: #{body_params.except(:client_secret)}")

      response = Faraday.post(token_url) do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = URI.encode_www_form(body_params)
      end

      Rails.logger.debug("Resposta do token: #{response.body}")

      begin
        token_data = JSON.parse(response.body, symbolize_names: true)
        
        if token_data[:error]
          Rails.logger.error("Erro ao obter token: #{token_data}")
          { error: true, error_description: token_data[:error_description] }
        else
          token_data
        end
      rescue JSON::ParserError => e
        Rails.logger.error("Erro ao parsear resposta do token: #{e.message}")
        { error: true, error_description: "Erro ao parsear resposta do token" }
      end
    end
  end
end
