class AuthController < ApplicationController
  # Step 1: Redirecionar o usuário para o TikTok para autorização
  def tiktok
    client_key = 'sbawualtc227t17bl4'
    
    # Definir redirect URI de forma mais explícita
    ngrok_base = '647b-2804-d4b-94d3-2a00-add1-9c47-9fd3-7578.ngrok-free.app'
    redirect_uri = "https://#{ngrok_base}/auth/callback"
    
    Rails.logger.debug("=" * 50)
    Rails.logger.debug("INICIANDO FLUXO DE AUTORIZAÇÃO TIKTOK")
    Rails.logger.debug("Client Key: #{client_key}")
    Rails.logger.debug("Redirect URI Original: #{redirect_uri}")
    
    # Encode do redirect_uri para verificação
    encoded_redirect_uri = URI.encode_www_form_component(redirect_uri)
    Rails.logger.debug("Redirect URI Encoded: #{encoded_redirect_uri}")

    # Atualizar scopes para corresponder aos configurados
    scope = 'user.info.basic,video.publish,video.upload,artist.certification.read,user.info.profile'
    scope = scope.split(',').map { |s| URI.encode_www_form_component(s) }.join('%20')
    Rails.logger.debug("Scopes Processados: #{scope}")

    # Gerar code_verifier e code_challenge para PKCE
    code_verifier = SecureRandom.urlsafe_base64(64)
    code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).gsub(/=+$/, '')

    Rails.logger.debug("Code Verifier: #{code_verifier}")
    Rails.logger.debug("Code Challenge: #{code_challenge}")

    # Salvar code_verifier na sessão para uso posterior
    session[:code_verifier] = code_verifier

    # Construir URL de autorização com parâmetros explicitamente separados
    auth_params = {
      client_key: client_key,
      scope: scope,
      response_type: 'code',
      redirect_uri: encoded_redirect_uri,
      code_challenge: code_challenge,
      code_challenge_method: 'S256'
    }

    @auth_url = "https://www.tiktok.com/v2/auth/authorize/?" + auth_params.map { |k, v| "#{k}=#{v}" }.join('&')

    Rails.logger.debug("URL de autorização gerada: #{@auth_url}")
    
    render 'tiktok'
  end

  # Step 2: O TikTok redireciona de volta com o código de autorização
  def callback
    # Logs de depuração detalhados
    Rails.logger.debug("=" * 50)
    Rails.logger.debug("INÍCIO DO MÉTODO DE CALLBACK")
    Rails.logger.debug("Parâmetros completos recebidos: #{params.to_json}")
    Rails.logger.debug("Cabeçalhos da requisição: #{request.headers.to_json}")
    Rails.logger.debug("URL da requisição: #{request.original_url}")
    Rails.logger.debug("Host da requisição: #{request.host}")
    Rails.logger.debug("Porta da requisição: #{request.port}")
    
    # Verificação de todos os parâmetros possíveis
    possible_code_params = [:code, :authorization_code, :auth_code]
    
    found_code = possible_code_params.find { |param| params[param].present? }
    
    if found_code
      code = params[found_code]
      Rails.logger.debug("Código de autorização encontrado no parâmetro: #{found_code}")
      Rails.logger.debug("Código de autorização: #{code}")

      # Recuperar code_verifier da sessão
      code_verifier = session[:code_verifier]
      Rails.logger.debug("Code Verifier recuperado da sessão: #{code_verifier}")

      if code_verifier.nil?
        Rails.logger.error("ERRO CRÍTICO: Code Verifier não encontrado na sessão")
        return render json: { 
          error: "Sessão inválida", 
          message: "Code Verifier não encontrado. Por favor, reinicie o processo de autorização." 
        }, status: :bad_request
      end

      # Passo 1: Trocar código por access token
      begin
        token_response = TikTok.get_access_token(code, code_verifier)
        Rails.logger.debug("Resposta completa do token: #{token_response.to_json}")

        if token_response[:error]
          Rails.logger.error("Erro ao obter token: #{token_response[:error_description]}")
          render json: { 
            error: token_response[:error], 
            error_description: token_response[:error_description],
            raw_params: params.to_json
          }, status: :unauthorized
        else
          # Processar token com sucesso
          Rails.logger.debug("Token obtido com sucesso!")
          
          # Limpar code_verifier da sessão após uso
          session.delete(:code_verifier)
          
          # Salvar informações importantes na sessão
          session[:tiktok_access_token] = token_response[:access_token]
          session[:tiktok_refresh_token] = token_response[:refresh_token]
          session[:tiktok_open_id] = token_response[:open_id]

          render json: {
            message: "Autorização concluída com sucesso!",
            open_id: token_response[:open_id],
            access_token_expires_in: token_response[:expires_in]
          }, status: :ok
        end
      rescue => e
        Rails.logger.error("Exceção durante a troca de token: #{e.class.name}")
        Rails.logger.error("Mensagem de erro: #{e.message}")
        Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
        render json: { 
          error: "Erro interno durante a autenticação", 
          exception: e.class.name, 
          message: e.message,
          raw_params: params.to_json
        }, status: :internal_server_error
      end
    else
      Rails.logger.error("NENHUM CÓDIGO DE AUTORIZAÇÃO ENCONTRADO")
      Rails.logger.error("Parâmetros recebidos: #{params.to_json}")
      render json: { 
        error: "Código de autorização não encontrado", 
        received_params: params.to_json,
        possible_params: possible_code_params
      }, status: :bad_request
    end
  rescue => e
    Rails.logger.error("ERRO FATAL NO MÉTODO DE CALLBACK")
    Rails.logger.error("Exceção: #{e.class.name}")
    Rails.logger.error("Mensagem: #{e.message}")
    Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
    render json: { 
      error: "Erro crítico no processo de autenticação", 
      exception: e.class.name, 
      message: e.message,
      raw_params: params.to_json
    }, status: :internal_server_error
  end
end