require 'rails_helper'

RSpec.describe TiktokProfileService, type: :service do
  describe '#fetch_profile_data' do
    # IMPORTANTE: Substitua pelo seu access_token real
    let(:access_token) { ENV['TIKTOK_TEST_ACCESS_TOKEN'] }

    it 'fetches complete TikTok profile data' do
      service = TiktokProfileService.new(access_token)
      
      begin
        profile_data = service.fetch_profile_data

        # Verificar campos obrigatórios
        expect(profile_data).to include(
          :name,
          :username,
          :bio_description,
          :followers,
          :total_views,
          :upload_count,
          :avg_last10_comments,
          :avg_last10_likes,
          :avg_last10_views,
          :engagement_rate,
          :joined_count,
          :likes
        )

        # Verificações adicionais
        expect(profile_data[:name]).to be_a(String)
        expect(profile_data[:followers]).to be_a(Integer)
        expect(profile_data[:engagement_rate]).to be_a(Float)
      rescue => e
        puts "Erro durante o teste: #{e.message}"
        puts e.backtrace.join("\n")
        raise
      end
    end
  end
end
