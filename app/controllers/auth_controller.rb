class AuthController < ApplicationController
  # Step 1: Redirecionar o usuário para o TikTok para autorização
  def tiktok
    # Configurações de autorização
    client_key = Rails.configuration.x.tiktok.client_key
    redirect_uri = "https://647b-2804-d4b-94d3-2a00-add1-9c47-9fd3-7578.ngrok-free.app/auth/callback"
    encoded_redirect_uri = URI.encode_www_form_component(redirect_uri)
    
    Rails.logger.debug("Redirect URI Encoded: #{encoded_redirect_uri}")
    
    # Scopes definidos pelo usuário
    test_scopes = ['user.info.basic']
    
    # Processar scopes para URL
    def process_scopes(scopes)
      processed_scopes = scopes.map do |scope|
        # Substituir espaços por %20 para codificação correta
        URI.encode_www_form_component(scope)
      end.join(' ')
      
      processed_scopes
    end
    
    # Processar scopes
    scope = process_scopes(test_scopes)
    
    # Gerar code verifier e challenge para PKCE
    code_verifier = SecureRandom.urlsafe_base64(32)
    code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).gsub(/=+$/, '')
    
    # Armazenar code verifier na sessão para uso posterior
    session[:code_verifier] = code_verifier
    
    # Gerar estado para prevenção de CSRF
    state = SecureRandom.hex(16)
    session[:auth_state] = state
    
    # Parâmetros de autorização
    auth_params = {
      client_key: client_key,
      redirect_uri: encoded_redirect_uri,
      response_type: 'code',
      scope: scope,
      state: state,
      code_challenge: code_challenge,
      code_challenge_method: 'S256'
    }
    
    # Construir URL de autorização
    base_url = "https://www.tiktok.com/v2/auth/authorize/?"
    authorization_url = base_url + auth_params.map { |k, v| "#{k}=#{v}" }.join('&')
    
    Rails.logger.debug("URL de Autorização: #{authorization_url}")
    
    # Redirecionar para URL de autorização do TikTok
    begin
      redirect_to authorization_url, allow_other_host: true
    rescue => e
      Rails.logger.error("Erro no redirecionamento: #{e.message}")
      render plain: "Erro de redirecionamento: #{e.message}", status: :internal_server_error
    end
  rescue => e
    Rails.logger.error("Erro durante a geração da URL de autorização: #{e.message}")
    Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
    render plain: "Erro de autorização: #{e.message}", status: :internal_server_error
  end

  # Step 2: O TikTok redireciona de volta com o código de autorização
  def callback
    # Configurações de autorização
    client_key = Rails.configuration.x.tiktok.client_key
    client_secret = Rails.configuration.x.tiktok.client_secret
    redirect_uri = "https://647b-2804-d4b-94d3-2a00-add1-9c47-9fd3-7578.ngrok-free.app/auth/callback"

    # Logs de depuração detalhados
    Rails.logger.debug("=" * 80)
    Rails.logger.debug("INÍCIO DO MÉTODO DE CALLBACK")
    Rails.logger.debug("Configurações:")
    Rails.logger.debug("  - Client Key: #{client_key}")
    Rails.logger.debug("  - Redirect URI: #{redirect_uri}")
    Rails.logger.debug("Parâmetros recebidos: #{params.to_json}")

    # Extrair código de autorização
    authorization_code = params[:code]
    state_param = params[:state]
    stored_state = session[:auth_state]

    # Logs de diagnóstico de estado
    Rails.logger.debug("Validação de Estado:")
    Rails.logger.debug("  - Estado Recebido: #{state_param}")
    Rails.logger.debug("  - Estado Armazenado: #{stored_state}")

    # Validações iniciais
    if authorization_code.blank?
      Rails.logger.error("ERRO: Código de autorização não encontrado")
      return render json: { 
        error: "Código de autorização ausente", 
        message: "Nenhum código de autorização foi recebido." 
      }, status: :bad_request
    end

    if state_param.blank? || stored_state.blank? || state_param != stored_state
      Rails.logger.error("ERRO DE SEGURANÇA: Estado inválido")
      return render json: { 
        error: "Erro de segurança", 
        message: "O estado da autorização não corresponde." 
      }, status: :unauthorized
    end

    # Recuperar code_verifier
    code_verifier = session[:code_verifier]
    if code_verifier.blank?
      Rails.logger.error("ERRO: Code Verifier não encontrado na sessão")
      return render json: { 
        error: "Sessão inválida", 
        message: "Code Verifier expirado ou não encontrado." 
      }, status: :bad_request
    end

    # Preparar parâmetros para troca de token
    token_params = {
      client_key: client_key,
      client_secret: client_secret,
      code: authorization_code,
      grant_type: 'authorization_code',
      redirect_uri: redirect_uri,
      code_verifier: code_verifier
    }

    # Logs de diagnóstico de token
    Rails.logger.debug("Parâmetros de Token:")
    token_params.each do |key, value|
      # Ocultar segredos sensíveis nos logs
      display_value = key.to_s.include?('secret') ? '*' * 10 : value
      Rails.logger.debug("  - #{key}: #{display_value}")
    end

    begin
      # Fazer requisição para obter token
      # NOTA: Usar a URL de token correta para o TikTok
      token_url = 'https://open.tiktokapis.com/v2/oauth/token/'
      Rails.logger.debug("URL de Token: #{token_url}")

      # Usar Faraday com configurações mais explícitas
      token_response = Faraday.new(url: token_url) do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end.post do |req|
        req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        req.body = URI.encode_www_form(token_params)
      end

      # Logs de resposta do token
      Rails.logger.debug("Resposta do Token:")
      Rails.logger.debug("  - Status: #{token_response.status}")
      Rails.logger.debug("  - Corpo: #{token_response.body}")
      Rails.logger.debug("  - Cabeçalhos: #{token_response.headers}")

      # Processar resposta do token
      if token_response.success?
        token_data = JSON.parse(token_response.body)
        
        # Limpar dados sensíveis da sessão
        session.delete(:code_verifier)
        session.delete(:auth_state)
        
        # Salvar informações do token
        session[:tiktok_access_token] = token_data['access_token']
        session[:tiktok_refresh_token] = token_data['refresh_token']
        session[:tiktok_open_id] = token_data['open_id']

        # Renderizar resposta de sucesso
        render json: {
          message: "Autorização concluída com sucesso!",
          open_id: token_data['open_id'],
          access_token_expires_in: token_data['expires_in']
        }, status: :ok

      else
        # Tratar falha na obtenção do token
        Rails.logger.error("Falha na obtenção do token:")
        Rails.logger.error("  - Status: #{token_response.status}")
        Rails.logger.error("  - Corpo: #{token_response.body}")
        Rails.logger.error("  - Cabeçalhos: #{token_response.headers}")
        
        render json: { 
          error: "Falha na autenticação", 
          details: token_response.body,
          status: token_response.status,
          headers: token_response.headers
        }, status: :unauthorized
      end

    rescue => e
      # Tratar exceções durante o processo de autenticação
      Rails.logger.error("Erro durante a autenticação:")
      Rails.logger.error("  - Classe: #{e.class.name}")
      Rails.logger.error("  - Mensagem: #{e.message}")
      Rails.logger.error("  - Backtrace: #{e.backtrace.join("\n")}")
      
      render json: { 
        error: "Erro interno", 
        message: e.message,
        exception_class: e.class.name
      }, status: :internal_server_error
    end
  end
end