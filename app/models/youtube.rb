class Youtube < ApplicationRecord
    validates :channel_id, presence: true, uniqueness: true
  
    def self.get_creator_data(access_token)
      service = YoutubeProfileService.new(access_token)
      channel_data = service.fetch_channel_data
      videos_data = service.fetch_last_10_videos
  
      new(
        name: channel_data[:name],
        username: channel_data[:username],
        channel_id: channel_data[:id],
        bio_description: channel_data[:description],
        followers: channel_data[:subscriber_count],
        upload_count: channel_data[:video_count],
        avg_last10_comments: calculate_avg(videos_data, :comment_count),
        avg_last10_likes: calculate_avg(videos_data, :like_count),
        avg_last10_views: calculate_avg(videos_data, :view_count),
        engagement_rate: calculate_engagement_rate(videos_data, channel_data[:subscriber_count]),
        joined_count: channel_data[:published_at].year
      )
    end
  
    private
  
    def self.calculate_avg(videos, metric)
      return 0 if videos.empty?
      videos.sum { |v| v[metric] }.to_f / videos.size
    end
  
    def self.calculate_engagement_rate(videos, subscribers)
      return 0 if subscribers.zero? || videos.empty?
      total_views = videos.sum { |v| v[:view_count] }
      (total_views.to_f / subscribers) * 100
    end
  end