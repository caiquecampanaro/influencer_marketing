require 'httparty'

class TiktokProfileService
  include HTTParty
  base_uri 'https://open.tiktokapis.com/v2'

  def initialize(access_token)
    @access_token = access_token
    @headers = {
      'Authorization' => "Bearer #{@access_token}",
      'Content-Type' => 'application/json'
    }
    @logger = Rails.logger
  end

  def fetch_profile_data
    @logger.debug(" Iniciando busca de dados do perfil TikTok")

    begin
      # Buscar informações do usuário
      user_info = fetch_user_info

      # Log detalhado dos dados brutos
      @logger.debug(" Dados brutos do usuário:")
      user_info.each do |key, value|
        @logger.debug("   #{key}: #{value}")
      end

      # Calcular métricas
      profile_data = {
        name: user_info['display_name'] || '',
        username: user_info['username'] || '',
        bio_description: user_info['bio_description'] || '',
        followers: user_info['follower_count'] || 0,
        total_views: 0,  # Não disponível na busca básica
        upload_count: 0, # Não disponível na busca básica
        avg_last10_comments: 0,
        avg_last10_likes: 0,
        avg_last10_views: 0,
        engagement_rate: 0,
        joined_count: calculate_account_age(user_info['create_time']),
        likes: user_info['likes_count'] || 0
      }

      @logger.info(" Dados do perfil TikTok coletados:")
      profile_data.each do |key, value|
        @logger.info("   #{key}: #{value}")
      end

      profile_data
    rescue => e
      @logger.error(" Erro ao buscar dados do perfil TikTok:")
      @logger.error("   Mensagem: #{e.message}")
      @logger.error("   Backtrace: #{e.backtrace.join("\n")}")
      raise
    end
  end

  private

  def fetch_user_info
    @logger.debug(" Buscando informações básicas do usuário")

    # Campos disponíveis no escopo user.info.basic
    response = self.class.get('/user/info/', 
      headers: @headers,
      query: { 
        fields: 'open_id,union_id,avatar_url,avatar_url_100,display_name,username,bio_description,follower_count,following_count,likes_count,create_time' 
      }
    )

    log_response(response, 'Informações do Usuário')

    raise "Erro ao buscar informações do usuário: #{response.body}" unless response.success?
    
    response.parsed_response['data']['user']
  end

  def calculate_account_age(create_time)
    @logger.debug(" Calculando idade da conta")

    if create_time
      # Converte timestamp para data e calcula diferença
      account_creation_date = Time.at(create_time.to_i)
      years = ((Time.now - account_creation_date) / 1.year.seconds).to_i
      @logger.debug("   Conta criada há #{years} anos")
      years
    else
      @logger.debug("   Não foi possível determinar a idade da conta")
      0
    end
  end

  def log_response(response, context)
    @logger.debug(" Resposta #{context}:")
    @logger.debug("   Status: #{response.code}")
    @logger.debug("   Headers: #{response.headers}")
    @logger.debug("   Body: #{response.body}")
  end
end
