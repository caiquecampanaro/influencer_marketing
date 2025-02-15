class Facebook < ApplicationRecord

  validates :username, presence: true, uniqueness: true

  def self.get_creator_data(access_token)

    return nil unless access_token


    service = FacebookAuthService.new
    user_info = service.get_user_info(access_token)


    create(
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
end