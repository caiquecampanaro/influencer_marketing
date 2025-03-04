require 'httparty'

class AuthController < ApplicationController
  def tiktok
    state = SecureRandom.hex(16)
    session[:oauth_state] = state

    scopes = URI.encode_www_form_component('user.info.basic,user.info.profile,user.info.stats,video.list')

    redirect_uri = 'https://5638-2804-d4b-94d3-2a00-9d95-aa9c-9f09-e8e0.ngrok-free.app/auth/callback'
    encoded_redirect_uri = URI.encode_www_form_component(redirect_uri)

    code_verifier = SecureRandom.urlsafe_base64(32)
    session[:code_verifier] = code_verifier
    code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).gsub('=', '')

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

    redirect_to authorization_url, allow_other_host: true
  rescue => e
    Rails.logger.error("Erro durante a geração da URL de autorização: #{e.message}")
    Rails.logger.error("Backtrace: #{e.backtrace.join("\n")}")
    render 'auth_error', locals: {
      error_code: 'authorization_error',
      error_description: "Não foi possível gerar URL de autorização: #{e.message}"
    }
  end

  def callback
    Rails.logger.debug("Parâmetros recebidos no callback: #{params}")

    if params[:error].present?
      error_description = params[:error_description] || 'Erro desconhecido'
      Rails.logger.error("Erro de autorização: #{error_description}")
      
      render 'auth_error', locals: {
        error_code: params[:error],
        error_description: error_description
      } and return
    end

    authorization_code = params[:code]
    
    state = params[:state]
    unless state == session[:oauth_state]
      Rails.logger.error("Estado inválido: possível ataque CSRF")
      render 'auth_error', locals: {
        error_code: 'csrf_error',
        error_description: 'Token de estado não corresponde'
      } and return
    end


    authorized_scopes = params[:scopes]&.split(',') || []
    Rails.logger.info("Escopos autorizados: #{authorized_scopes}")

    token_params = {
      client_key: ENV['TIKTOK_CLIENT_KEY'],
      client_secret: ENV['TIKTOK_CLIENT_SECRET'],
      code: authorization_code,
      redirect_uri: 'https://5638-2804-d4b-94d3-2a00-9d95-aa9c-9f09-e8e0.ngrok-free.app/auth/callback',
      grant_type: 'authorization_code',
      code_verifier: session[:code_verifier]
    }

    begin
      response = HTTParty.post(
        'https://open.tiktokapis.com/v2/oauth/token/',
        body: token_params,
        headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
      )

      Rails.logger.debug("Resposta do token: #{response.body}")

      if response.success?
        session[:tiktok_access_token] = response.parsed_response['access_token']
        session[:tiktok_refresh_token] = response.parsed_response['refresh_token']
        session[:tiktok_authorized_scopes] = authorized_scopes

        session[:tiktok_access_token] = response['access_token']

        redirect_to auth_success_path
      else
        Rails.logger.error("Erro ao obter token: #{response.body}")
        render 'auth_error', locals: {
          error_code: 'token_error',
          error_description: response.body
        }
      end
    rescue => e
      Rails.logger.error("Exceção na troca de token: #{e.message}")
      render 'auth_error', locals: {
        error_code: 'exception_error',
        error_description: e.message
      }
    end
  end


  def success
    @tiktok_service = TiktokProfileService.new(session[:tiktok_access_token])
    @profile_data = @tiktok_service.fetch_profile_data

    @tiktok_profile = TikTok.find_or_initialize_by(username: @profile_data[:username])
    @tiktok_profile.assign_attributes(@profile_data)

    if @tiktok_profile.new_record?
      @tiktok_profile.save
      @message = "Novo perfil TikTok criado com sucesso!"
    else
      @tiktok_profile.save if @tiktok_profile.changed?
      @message = "Os dados do perfil foram atualizados com sucesso!"
    end

    render :success
  end

  def list_videos
    access_token = session[:tiktok_access_token]  
    tiktok_service = TiktokProfileService.new(access_token)
    @video_ids = tiktok_service.fetch_video_list

    render json: @video_ids 
  end

  def facebook
    state = SecureRandom.hex(16)
    session[:oauth_state] = state

    redirect_to "https://www.facebook.com/v22.0/dialog/oauth?" + {
      client_id: ENV['FACEBOOK_APP_ID'],
      redirect_uri: 'https://ab3b-2804-d4b-94d3-2a00-bd15-68b2-f7f3-ef88.ngrok-free.app/auth/facebook/callback',
      state: state,
      scope: 'public_profile,email',
      display: 'popup'
    }.to_query
  end

  def facebook_callback
    return render plain: "Erro de segurança: State inválido", status: 403 if params[:state] != session[:oauth_state]

    service = FacebookAuthService.new
    token_response = service.get_access_token(params[:code], 'https://ab3b-2804-d4b-94d3-2a00-bd15-68b2-f7f3-ef88.ngrok-free.app/auth/facebook/callback')
    user_info = service.get_user_info(token_response['access_token'])

    facebook = Facebook.create(
      name: user_info['name'],
      username: user_info['id'],
      bio_description: "",
      followers: 0,
      upload_count: 0,
      avg_last10_comments: 0,
      avg_last10_likes: 0,
      avg_last10_views: 0,
      engagement_rate: 0.0,
      joined_count: 1
    )
  end

  def youtube_authorize
    state = SecureRandom.hex(16)
    session[:oauth_state] = state
  
    auth_params = {
      client_id: ENV['GOOGLE_CLIENT_ID'],
      redirect_uri: ENV['YOUTUBE_REDIRECT_URI'],
      response_type: 'code',
      scope: 'https://www.googleapis.com/auth/youtube.readonly',
      state: state,
      access_type: 'offline',
      prompt: 'consent'
    }
  
    redirect_to "https://accounts.google.com/o/oauth2/v2/auth?#{auth_params.to_query}"
  end

  def youtube_callback
    if params[:state] != session[:oauth_state]
      redirect_to root_path, alert: 'Invalid state parameter'
      return
    end

    begin
      token_response = exchange_code(params[:code])
      creator = Youtube.get_creator_data(token_response['access_token'])
      
      if creator.save
        redirect_to dashboard_path, notice: 'YouTube data imported!'
      else
        redirect_back alert: "Error saving data: #{creator.errors.full_messages}"
      end
    rescue => e
      Rails.logger.error "YouTube API Error: #{e.message}"
      redirect_to root_path, alert: "Error connecting to YouTube: #{e.message}"
    end
  end

  private

  def exchange_code(code)
    HTTParty.post('https://oauth2.googleapis.com/token', {
      body: {
        code: code,
        client_id: ENV['GOOGLE_CLIENT_ID'],
        client_secret: ENV['GOOGLE_CLIENT_SECRET'],
        redirect_uri: ENV['YOUTUBE_REDIRECT_URI'],
        grant_type: 'authorization_code'
      }
    })
  end
end