class CreateTikToks < ActiveRecord::Migration[8.0]
  def change
    create_table :tik_toks do |t|
      t.string :name
      t.string :username
      t.text :bio_description
      t.integer :followers
      t.integer :total_views
      t.integer :upload_count
      t.integer :avg_last10_comments
      t.integer :avg_last10_likes
      t.integer :avg_last10_views
      t.float :engagement_rate
      t.integer :joined_count
      t.bigint :likes

      t.timestamps
    end
  end
end
