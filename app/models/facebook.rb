class Facebook < ApplicationRecord
  # Adicionando as colunas ao banco de dados conforme os dados da API do Facebook
  validates :username, presence: true, uniqueness: true

  # Função para obter os dados do criador do Facebook
  def self.get_creator_data(access_token)
    # Valida o access token
    return nil unless access_token

    # Chama o serviço do Facebook para obter as informações do criador
    service = FacebookAuthService.new
    user_info = service.get_user_info(access_token)

    # Trata os dados antes de salvar no banco
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