class CreateInfluencers < ActiveRecord::Migration[8.0]
  def change
    create_table :influencers do |t|
      t.string :name
      t.string :username
      t.string :platform
      t.integer :followers
      t.string :email

      t.timestamps
    end
    add_index :influencers, :username, unique: true
  end
end
