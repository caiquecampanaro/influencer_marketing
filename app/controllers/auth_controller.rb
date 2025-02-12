require 'httparty'

class AuthController < ApplicationController
  # Step 1: Redirecionar o usuário para o TikTok para autorização
  def tiktok
    # Gerar state token para prevenção de CSRF
    state = SecureRandom.hex(16)
    session[:oauth_state] = state

    # Definir múltiplos escopos (codificados corretamente)
    scopes = URI.encode_www_form_component('user.info.basic,user.info.profile,user.info.stats')

    # URL de redirecionamento exata do TikTok
    redirect_uri = 'https://5a40-2804-d4b-94d3-2a00-2071-a70d-d2a6-40cc.ngrok-free.app/auth/callback'
    encoded_redirect_uri = URI.encode_www_form_component(redirect_uri)

    # Gerar code challenge para PKCE
    code_verifier = SecureRandom.urlsafe_base64(32)
    session[:code_verifier] = code_verifier
    code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).gsub('=', '')

    # Construir URL de autorização com parâmetros corretos
    authorization_url = "https://www.tiktok.com/v2/auth/authorize/?" +
      "client_key=#{ENV['TIKTOK_CLIENT_KEY']}" +
      "&response_type=code" +
      "&scope=#{scopes}" +
      "&redirect_uri=#{encoded_redirect_uri}" +
      "&state=#{state}" +
      "&code_challenge=#{code_challenge}" +
      "&code_challenge_method=S256" +
      "&disable_auto_auth=0"

    Rails.logger.debug("URL de Autorização: #{authorization_url}")

    # Redirecionar para autorização do TikTok
    redirect_to authorization_url, allow_other_host: true
  rescue => e
    Rails.logger.error("Erro durante a geração da URL de autorização: #{e.message}")
    Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
    render 'auth_error', locals: {
      error_code: 'authorization_error',
      error_description: "Não foi possível gerar URL de autorização: #{e.message}"
    }
  end

  # Step 2: O TikTok redireciona de volta com o código de autorização
  def callback
    Rails.logger.debug("Parâmetros recebidos no callback: #{params}")

    # Verificar se há erros no retorno do TikTok
    if params[:error].present?
      error_description = params[:error_description] || 'Erro desconhecido'
      Rails.logger.error("Erro de autorização: #{error_description}")
      
      render 'auth_error', locals: {
        error_code: params[:error],
        error_description: error_description
      } and return
    end

    # Extrair código de autorização
    authorization_code = params[:code]
    
    # Validar estado para prevenir CSRF
    state = params[:state]
    unless state == session[:oauth_state]
      Rails.logger.error("Estado inválido: possível ataque CSRF")
      render 'auth_error', locals: {
        error_code: 'csrf_error',
        error_description: 'Token de estado não corresponde'
      } and return
    end

    # Obter os escopos autorizados
    authorized_scopes = params[:scopes]&.split(',') || []
    Rails.logger.info("Escopos autorizados: #{authorized_scopes}")

    # Preparar dados para troca de código por token
    token_params = {
      client_key: ENV['TIKTOK_CLIENT_KEY'],
      client_secret: ENV['TIKTOK_CLIENT_SECRET'],
      code: authorization_code,
      redirect_uri: 'https://5a40-2804-d4b-94d3-2a00-2071-a70d-d2a6-40cc.ngrok-free.app/auth/callback',
      grant_type: 'authorization_code',
      code_verifier: session[:code_verifier]
    }

    begin
      # Trocar código por token de acesso
      response = HTTParty.post(
        'https://open.tiktokapis.com/v2/oauth/token/',
        body: token_params,
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
      )

      Rails.logger.debug("Resposta do token: #{response.body}")

      if response.success?
        # Armazenar tokens e informações na sessão
        session[:tiktok_access_token] = response.parsed_response['access_token']
        session[:tiktok_refresh_token] = response.parsed_response['refresh_token']
        session[:tiktok_authorized_scopes] = authorized_scopes

        # Redirecionar para página de sucesso
        redirect_to auth_success_path
      else
        # Tratar erro na obtenção do token
        Rails.logger.error("Erro ao obter token: #{response.body}")
        render 'auth_error', locals: {
          error_code: 'token_error',
          error_description: response.body
        }
      end
    rescue => e
      # Tratar exceções durante a troca de token
      Rails.logger.error("Exceção na troca de token: #{e.message}")
      render 'auth_error', locals: {
        error_code: 'exception_error',
        error_description: e.message
      }
    end
  end

  # Página de sucesso após autorização
  def success
    unless session[:tiktok_access_token]
      redirect_to auth_tiktok_path, alert: "Você precisa autorizar o aplicativo primeiro."
      return
    end

    # Buscar dados do perfil
    begin
      profile_service = TiktokProfileService.new(session[:tiktok_access_token])
      @profile_data = profile_service.fetch_profile_data

      # Salvar no banco de dados
      @tiktok_profile = TikTok.create!(@profile_data)

      # Preparar variáveis para view
      @access_token = session[:tiktok_access_token]
      @refresh_token = session[:tiktok_refresh_token]
      @authorized_scopes = session[:tiktok_authorized_scopes]

    rescue => e
      Rails.logger.error("Erro ao buscar perfil do TikTok: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      
      # Renderizar página de erro com detalhes
      render 'auth_error', locals: {
        error_code: 'profile_fetch_error',
        error_description: "Não foi possível buscar os dados do perfil: #{e.message}"
      }
    end
  end
end