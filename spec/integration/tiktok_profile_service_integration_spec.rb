require 'rails_helper'

RSpec.describe "TikTok Profile Service Integration", type: :integration do
  describe 'Fetch User Info' do
    let(:access_token) { ENV['TIKTOK_TEST_ACCESS_TOKEN'] }

    it 'retrieves basic user information successfully' do
      service = TiktokProfileService.new(access_token)
      
      # Executar a busca de dados
      profile_data = service.fetch_profile_data

      # Verificações básicas
      expect(profile_data).to be_a(Hash)
      
      # Verificar campos obrigatórios
      expect(profile_data[:name]).to be_present
      expect(profile_data[:username]).to be_present
      expect(profile_data[:followers]).to be_a(Integer)
      expect(profile_data[:followers]).to be >= 0

      # Verificações adicionais
      expect(profile_data[:joined_count]).to be_a(Integer)
      expect(profile_data[:likes]).to be_a(Integer)
    end

    it 'handles invalid access token' do
      invalid_token = 'invalid_token_123'
      service = TiktokProfileService.new(invalid_token)
      
      # Verificar tratamento de erro
      expect {
        service.fetch_profile_data
      }.to raise_error(RuntimeError, /Erro ao buscar informações do usuário/)
    end
  end
end
