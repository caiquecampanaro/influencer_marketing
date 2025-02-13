require 'httparty'

class TiktokProfileService
  include HTTParty
  base_uri 'https://open.tiktokapis.com/v2'

  def initialize(access_token)
    @access_token = access_token
    @headers = {
      'Authorization' => "Bearer #{@access_token}",
      'Content-Type' => 'application/x-www-form-urlencoded'
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

      # Buscar informações do usuário  
      video_list = fetch_video_list
      @logger.debug(" Dados brutos da lista de vídeos:")
      video_list.each do |key, value|
        @logger.debug("   #{key}: #{value}")
      end

      # Buscar informações do usuário  
      video_data = fetch_video_data(video_list)
      @logger.debug(" Dados brutos dos vídeos:")
      video_data.each do |key, value|
        @logger.debug("   #{key}: #{value}")
      end

      # Calcular métricas após obter todos os dados
      total_views = video_data['videos'].sum { |video| video['view_count'].to_i}
      avg_last10_comments = video_data['videos'].last(10).sum { |video| video['comment_count'].to_i } / [video_data['videos'].size, 10].min
      avg_last10_likes = video_data['videos'].last(10).sum { |video| video['like_count'].to_i } / [video_data['videos'].size, 10].min
      avg_last10_views = video_data['videos'].last(10).sum { |video| video['view_count'].to_i } / [video_data['videos'].size, 10].min
      total_followers = user_info['follower_count'] || 0
      engagement_rate = avg_last10_views / total_followers

      # Preparar dados do perfil
      profile_data = {
        name: user_info['display_name'] || '',
        username: user_info['username'] || '',
        bio_description: user_info['bio_description'] || '',
        followers: total_followers,
        total_views: total_views,
        upload_count: user_info['video_count'] || 0,
        avg_last10_comments: avg_last10_comments,
        avg_last10_likes: avg_last10_likes,
        avg_last10_views: avg_last10_views,
        engagement_rate: engagement_rate,
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

  def fetch_video_data(video_ids)
    Rails.logger.info("Fetching video data for IDs: #{video_ids}")

    response = self.class.post(
      '/video/query/?fields=view_count,comment_count,like_count',
      headers: {
        'Authorization' => "Bearer #{@access_token}",
        'Content-Type' => 'application/x-www-form-urlencoded'
      },
      body: {
        filters: {
          video_ids: video_ids
        }
      }.to_json
    )

    Rails.logger.info("Response Code: #{response.code}")
    Rails.logger.info("Response Body: #{response.body}")

    if response.success?
      video_data = response.parsed_response['data']
      return video_data
    else
      Rails.logger.error("Erro ao buscar os dados do vídeo: #{response.message}")
      raise "Erro ao buscar os dados do vídeo"
    end
  end

  def fetch_video_list(max_count = 10)
    Rails.logger.info("Fetching video list with access token: #{@access_token}")

    response = self.class.post("/video/list/?fields=cover_image_url,id,title", 
      headers: {
        'Authorization' => "Bearer #{@access_token}",
        'Content-Type' => 'application/json' 
      },
      body: {
        max_count: max_count
      }.to_json
    )

    Rails.logger.info("Response Code: #{response.code}")  
    Rails.logger.info("Response Body: #{response.body}")  

    if response.success?
      video_data = response.parsed_response['data']['videos']
      video_ids = video_data.map { |video| video['id'] }
      return video_ids
    else
      Rails.logger.error("Erro ao buscar a lista de vídeos: #{response.message}")
      raise "Erro ao buscar a lista de vídeos"
    end
  end

  def fetch_user_info
    @logger.debug(" Buscando informações básicas do usuário")

    # Campos disponíveis no escopo user.info.basic
    response = self.class.get('/user/info/',
      headers: @headers,
      query: {
        fields: 'open_id,union_id,avatar_url,avatar_url_100,display_name,username,bio_description,follower_count,following_count,likes_count,create_time,video_count' 
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
