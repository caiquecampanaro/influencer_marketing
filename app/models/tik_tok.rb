class TikTok < ApplicationRecord
  validates :username, presence: true, uniqueness: true

  def self.get_creator_data(username, access_token)
    begin
      # Inicializa a conexão com a API do TikTok
      conn = Faraday.new do |f|
        f.request :json
        f.response :json
      end

      # Busca dados básicos do usuário
      user_info = fetch_user_info(conn, username, access_token)
      return user_info if user_info[:error].present?

      # Busca os últimos vídeos do usuário
      videos_info = fetch_videos_info(conn, username, access_token)
      return videos_info if videos_info[:error].present?

      # Processa os dados dos últimos 10 vídeos
      last_10_stats = calculate_video_stats(videos_info[:videos])

      # Calcula engagement rate
      engagement_rate = calculate_engagement_rate(last_10_stats[:avg_views], user_info[:stats][:followers])

      {
        name: user_info[:user][:display_name],
        username: username,
        bio_description: user_info[:user][:bio_description],
        followers: user_info[:stats][:followers],
        total_views: user_info[:stats][:total_views],
        upload_count: user_info[:stats][:video_count],
        avg_last10_comments: last_10_stats[:avg_comments],
        avg_last10_likes: last_10_stats[:avg_likes],
        avg_last10_views: last_10_stats[:avg_views],
        engagement_rate: engagement_rate,
        joined_count: user_info[:stats][:following],
        likes: user_info[:stats][:likes]
      }
    rescue StandardError => e
      Rails.logger.error("Erro ao buscar dados do creator TikTok: #{e.message}")
      { error: "Falha ao buscar dados do creator", details: e.message }
    end
  end

  private

  def self.fetch_user_info(conn, username, access_token)
    response = conn.get("https://open.tiktokapis.com/v2/user/info/") do |req|
      req.headers["Authorization"] = "Bearer #{access_token}"
      req.params = {
        fields: ["display_name", "bio_description", "follower_count", "following_count", "likes_count", "video_count"]
      }
    end

    if response.success?
      data = response.body["data"]
      {
        user: {
          display_name: data["display_name"],
          bio_description: data["bio_description"]
        },
        stats: {
          followers: data["follower_count"],
          following: data["following_count"],
          likes: data["likes_count"],
          video_count: data["video_count"],
          total_views: 0  # Será atualizado com a soma das views dos vídeos
        }
      }
    else
      { error: response.body["error"] || "Falha ao buscar informações do usuário" }
    end
  end

  def self.fetch_videos_info(conn, username, access_token)
    response = conn.get("https://open.tiktokapis.com/v2/video/list/") do |req|
      req.headers["Authorization"] = "Bearer #{access_token}"
      req.params = {
        fields: ["id", "like_count", "comment_count", "view_count", "create_time"],
        max_count: 10
      }
    end

    if response.success?
      {
        videos: response.body["data"]["videos"] || []
      }
    else
      { error: response.body["error"] || "Falha ao buscar vídeos do usuário" }
    end
  end

  def self.calculate_video_stats(videos)
    return { avg_comments: 0, avg_likes: 0, avg_views: 0 } if videos.empty?

    total_comments = 0
    total_likes = 0
    total_views = 0

    videos.each do |video|
      total_comments += video["comment_count"].to_i
      total_likes += video["like_count"].to_i
      total_views += video["view_count"].to_i
    end

    video_count = videos.length

    {
      avg_comments: (total_comments.to_f / video_count).round,
      avg_likes: (total_likes.to_f / video_count).round,
      avg_views: (total_views.to_f / video_count).round
    }
  end

  def self.calculate_engagement_rate(avg_views, followers)
    return 0.0 if followers.to_i.zero?
    ((avg_views.to_f / followers) * 100).round(2)
  end
end
