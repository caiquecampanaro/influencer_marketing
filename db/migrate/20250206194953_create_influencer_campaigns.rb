class CreateInfluencerCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :influencer_campaigns do |t|
      t.references :influencer, null: false, foreign_key: true
      t.references :campaign, null: false, foreign_key: true
      t.jsonb :custom_metrics

      t.timestamps
    end
  end
end
