class AuthController < ApplicationController
  # Step 1: Redirecionar o usuário para o TikTok para autorização
  def tiktok
    # Configurações de autorização para novo sandbox
    client_key = 'sbawf4zxt54h5z7in6'
    client_secret = 'G9h5MBZ765gAEpHhH6Qys1pvG57O0T4x'
    
    # Log de diagnóstico detalhado
    Rails.logger.debug("=" * 80)
    Rails.logger.debug("DIAGNÓSTICO CRÍTICO DE AUTORIZAÇÃO TIKTOK")
    Rails.logger.debug("Client Key: #{client_key}")
    Rails.logger.debug("Comprimento da Client Key: #{client_key.length}")
    
    # Verificações de segurança adicionais
    if client_key.nil? || client_key.empty?
      error_message = "ERRO CRÍTICO: Client Key não configurada"
      Rails.logger.error(error_message)
      return render plain: error_message, status: :internal_server_error
    end
    
    # Adicionar log de ambiente de desenvolvimento
    Rails.logger.debug("Ambiente: #{Rails.env}")
    Rails.logger.debug("Configurações do TikTok:")
    Rails.logger.debug("  - Client Key: #{client_key}")
    
    # Informações de configuração
    # client_secret = 'QDDbiHtTVWlU8kQWHQbuj6R3qOdOgGqD'
    
    # Logs de diagnóstico detalhados
    # Rails.logger.debug("=" * 50)
    # Rails.logger.debug("DIAGNÓSTICO DETALHADO DE AUTORIZAÇÃO TIKTOK")
    # Rails.logger.debug("Client Key: #{client_key}")
    # Rails.logger.debug("Client Secret: #{client_secret[0,5]}...#{client_secret[-5,5]}")
    
    # Verificar tamanho e formato da client_key
    Rails.logger.debug("Tamanho da Client Key: #{client_key.length}")
    Rails.logger.debug("Formato da Client Key: #{client_key =~ /^[a-z0-9]+$/ ? 'Válido' : 'Inválido'}")
    
    # Configurar redirect URI corretamente
    redirect_uri = "https://647b-2804-d4b-94d3-2a00-add1-9c47-9fd3-7578.ngrok-free.app/auth/callback"
    encoded_redirect_uri = URI.encode_www_form_component(redirect_uri)
    
    # Logs de diagnóstico do redirect URI
    Rails.logger.debug("=" * 50)
    Rails.logger.debug("DIAGNÓSTICO DE REDIRECT URI")
    Rails.logger.debug("Redirect URI Original: #{redirect_uri}")
    Rails.logger.debug("Redirect URI Encoded: #{encoded_redirect_uri}")
    
    # Scopes definidos pelo usuário
    test_scopes = [
      'user.info.basic', 
      'video.upload'
    ]
    
    # Diagnóstico CRÍTICO de scopes
    def diagnose_tiktok_scopes(scopes)
      Rails.logger.error("=" * 80)
      Rails.logger.error("🚨 DIAGNÓSTICO CRÍTICO DE SCOPES TIKTOK 🚨")
      
      scopes.each do |scope|
        case scope
        when 'user.info.basic'
          Rails.logger.error("✅ user.info.basic:")
          Rails.logger.error("   - Descrição: Informações básicas do perfil")
          Rails.logger.error("   - Dados: open id, avatar, nome de exibição")
          Rails.logger.error("   - Status: Verificando elegibilidade...")
        when 'video.upload'
          Rails.logger.error("✅ video.upload:")
          Rails.logger.error("   - Descrição: Upload de conteúdo como rascunho")
          Rails.logger.error("   - Ação: Compartilhar conteúdo para edição")
          Rails.logger.error("   - Status: Verificando permissões...")
        else
          Rails.logger.error("❌ Scope Desconhecido: #{scope}")
        end
      end
      
      # Verificações adicionais
      Rails.logger.error("\n🔍 VERIFICAÇÕES ADICIONAIS:")
      Rails.logger.error("   - Client Key Length: #{client_key.length}")
      Rails.logger.error("   - Redirect URI: #{redirect_uri}")
      Rails.logger.error("   - Ambiente: #{Rails.env}")
      
      Rails.logger.error("=" * 80)
    end

    # Executar diagnóstico detalhado
    diagnose_tiktok_scopes(test_scopes)
    
    # Função para processar scopes corretamente
    def process_scopes(scopes)
      # Processar scopes sem modificações
      processed_scopes = scopes.map { |s| URI.encode_www_form_component(s) }.join('%20')
      
      Rails.logger.error("🔐 PROCESSAMENTO FINAL DE SCOPES:")
      Rails.logger.error("   - Scopes Originais: #{scopes.join(', ')}")
      Rails.logger.error("   - Scopes Processados: #{processed_scopes}")
      
      processed_scopes
    end
    
    # Processar scopes
    scope = process_scopes(test_scopes)
    
    Rails.logger.debug("Scopes Originais: #{test_scopes.join(' ')}")
    Rails.logger.debug("Scopes Processados: #{scope}")

    # Geração de PKCE
    code_verifier = SecureRandom.urlsafe_base64(64).tr('=', '')
    sha256 = Digest::SHA256.digest(code_verifier)
    code_challenge = Base64.strict_encode64(sha256).tr('=', '')
    
    # Salvar code_verifier na sessão
    session[:code_verifier] = code_verifier
    
    # Parâmetros de autorização
    auth_params = {
      client_key: client_key,
      scope: scope,
      response_type: 'code',
      redirect_uri: encoded_redirect_uri,
      code_challenge: code_challenge,
      code_challenge_method: 'S256'
    }
    
    # Log de diagnóstico
    Rails.logger.debug("Parâmetros de Autorização:")
    auth_params.each do |key, value|
      Rails.logger.debug("  - #{key}: #{value}")
    end
    
    # Construir URL de autorização
    @auth_url = "https://www.tiktok.com/v2/auth/authorize/?" + 
                auth_params.map { |k, v| "#{k}=#{v}" }.join('&')
    
    Rails.logger.debug("URL de Autorização Gerada: #{@auth_url}")
    
    render 'tiktok'
  rescue => e
    Rails.logger.error("Erro durante a geração da URL de autorização: #{e.message}")
    Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
    render plain: "Erro durante a autorização: #{e.message}", status: :internal_server_error
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