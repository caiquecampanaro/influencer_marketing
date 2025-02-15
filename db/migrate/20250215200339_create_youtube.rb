class CreateYoutube < ActiveRecord::Migration[8.0]
  def change
    create_table :youtubes do |t|
      t.string :name
      t.string :username
      t.string :channel_id
      t.text :bio_description
      t.integer :followers
      t.integer :upload_count
      t.integer :avg_last10_comments
      t.integer :avg_last10_likes
      t.integer :avg_last10_views
      t.float :engagement_rate
      t.integer :joined_count
      
      t.timestamps
    end
  end
end
