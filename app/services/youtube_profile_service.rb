class YoutubeProfileService
    API_KEY = ENV['YOUTUBE_API_KEY']
    CLIENT_ID = ENV['GOOGLE_CLIENT_ID']
    CLIENT_SECRET = ENV['GOOGLE_CLIENT_SECRET']
    REDIRECT_URI = ENV['YOUTUBE_REDIRECT_URI']
  
    def initialize(access_token = nil)
      @access_token = access_token
    end
  
    def fetch_channel_data
      response = HTTParty.get(
        'https://www.googleapis.com/youtube/v3/channels',
        headers: authorization_header,
        query: {
          part: 'snippet,statistics',
          mine: true
        }
      )
  
      handle_response(response)['items'].first.tap do |channel|
        return {
          id: channel['id'],
          name: channel.dig('snippet', 'title'),
          username: channel.dig('snippet', 'customUrl'),
          description: channel.dig('snippet', 'description'),
          subscriber_count: channel.dig('statistics', 'subscriberCount').to_i,
          video_count: channel.dig('statistics', 'videoCount').to_i,
          published_at: Time.parse(channel.dig('snippet', 'publishedAt'))
        }
      end
    end
  
    def fetch_last_10_videos
      response = HTTParty.get(
        'https://www.googleapis.com/youtube/v3/search',
        headers: authorization_header,
        query: {
          part: 'snippet',
          type: 'video',
          forMine: true,
          maxResults: 10,
          order: 'date'
        }
      )
  
      video_ids = handle_response(response)['items'].map { |item| item.dig('id', 'videoId') }
      fetch_videos_stats(video_ids)
    end
  
    private
  
    def fetch_videos_stats(video_ids)
      return [] if video_ids.empty?
  
      response = HTTParty.get(
        'https://www.googleapis.com/youtube/v3/videos',
        headers: authorization_header,
        query: {
          part: 'statistics',
          id: video_ids.join(',')
        }
      )
  
      handle_response(response)['items'].map do |video|
        stats = video['statistics']
        {
          view_count: stats['viewCount'].to_i,
          like_count: stats['likeCount'].to_i,
          comment_count: stats['commentCount'].to_i
        }
      end
    end
  
    def authorization_header
      { 'Authorization' => "Bearer #{@access_token}" }
    end
  
    def handle_response(response)
      if response.success?
        JSON.parse(response.body)
      else
        error = JSON.parse(response.body)['error']
        raise "YouTube API Error #{error['code']}: #{error['message']}"
      end
    end
  end