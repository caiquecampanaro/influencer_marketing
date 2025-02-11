class AuthController < ApplicationController
  # Step 1: Redirecionar o usuário para o TikTok para autorização
  def tiktok
    client_key = 'sbawualtc227t17bl4'
    redirect_uri = 'https://647b-2804-d4b-94d3-2a00-add1-9c47-9fd3-7578.ngrok-free.app/callback'
    scope = 'user.info.profile,video.list,user.info.stats,artist.certification.read'

    auth_url = "https://www.tiktok.com/v2/auth/authorize/?client_key=#{client_key}&scope=#{scope}&response_type=code&redirect_uri=#{URI.encode_www_form_component(redirect_uri)}"
    Rails.logger.debug("URL de autorização: #{auth_url}")
    redirect_to auth_url, allow_other_host: true
  end

  # Step 2: O TikTok redireciona de volta com o código de autorização
  def callback
    Rails.logger.debug("Parâmetros completos recebidos: #{params.inspect}")
    Rails.logger.debug("Cabeçalhos da requisição: #{request.headers.inspect}")
    
    if params[:code].present?
      code = params[:code]
      Rails.logger.debug("Código de autorização recebido: #{code}")

      # Passo 1: Trocar código por access token
      token_response = TikTok.get_access_token(code)
      Rails.logger.debug("Resposta do token: #{token_response.inspect}")

      if token_response[:error]
        Rails.logger.error("Erro ao obter access token: #{token_response[:error_description]}")
        render json: { 
          error: token_response[:error],
          error_description: token_response[:error_description],
          log_id: token_response[:log_id]
        }, status: :unauthorized
        return
      end

      # Salvar os tokens
      session[:tiktok_access_token] = token_response[:access_token]
      session[:tiktok_refresh_token] = token_response[:refresh_token]
      session[:tiktok_open_id] = token_response[:open_id]

      # Continue com o fluxo...
    else
      Rails.logger.error("Nenhum código de autorização encontrado nos parâmetros")
      Rails.logger.error("Parâmetros recebidos: #{params}")
      render json: { error: "Código de autorização não recebido." }, status: :bad_request
    end
  end

  # Método para testar a busca de dados diretamente
  def test_creator_data
    username = params[:username]
    access_token = session[:tiktok_access_token]

    if username.blank?
      render json: { error: "Username é obrigatório" }, status: :bad_request
      return
    end

    if access_token.blank?
      render json: { error: "Não há token de acesso. Faça a autenticação primeiro." }, status: :unauthorized
      return
    end

    creator_data = TikTok.get_creator_data(username, access_token)
    
    if creator_data[:error]
      render json: creator_data, status: :unprocessable_entity
    else
      render json: { 
        success: true,
        creator_data: creator_data
      }
    end
  end
end