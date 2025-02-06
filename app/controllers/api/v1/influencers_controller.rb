module Api
  module V1
    class InfluencersController < ApplicationController
      before_action :set_influencer, only: [:show, :update, :destroy]
  
      # List all influencers
      def index
        @influencers = Influencer.all
        render json: @influencers
      end
  
      # Show a specific influencer
      def show
        render json: @influencer
      end
  
      # Create a new influencer
      def create
        @influencer = Influencer.new(influencer_params)
  
        if @influencer.save
          render json: @influencer, status: :created
        else
          render json: @influencer.errors, status: :unprocessable_entity
        end
      end
  
      # Update an influencer
      def update
        if @influencer.update(influencer_params)
          render json: @influencer
        else
          render json: @influencer.errors, status: :unprocessable_entity
        end
      end
  
      # Delete an influencer
      def destroy
        @influencer.destroy
        head :no_content
      end

      # Sincroniza influenciadores da API externa
      def sync
        # Faz a requisição GET para a API externa
        response = Faraday.get('https://jsonplaceholder.typicode.com/users')

        # Se a requisição foi bem-sucedida, processa os dados
        if response.status == 200
          influencers_data = JSON.parse(response.body)

          platforms = ['Instagram', 'TikTok', 'YouTube']

          influencers_data.each do |influencer_data|
            # Evita duplicação: verifica se o influenciador já existe pelo username
            influencer = Influencer.find_or_initialize_by(username: influencer_data['username'])
            
            influencer.name = influencer_data['name']
            influencer.username = influencer_data['username']
            influencer.platform = platforms.sample # Como exemplo, você pode definir o valor da plataforma aqui
            influencer.followers = rand(1000..100000) # Exemplo de número de seguidores aleatório
            influencer.email = influencer_data['email'] # Usei o campo de email da API

            influencer.save if influencer.changed? # Salva o influenciador se houver alterações
          end

          render json: { message: 'Influencers synced successfully' }, status: :ok
        else
          render json: { error: 'Failed to fetch data from external API' }, status: :unprocessable_entity
        end
      end
  
      private
  
      def set_influencer
        @influencer = Influencer.find(params[:id])
      end
  
      def influencer_params
        params.require(:influencer).permit(:name, :username, :platform, :followers, :email)
      end
    end
  end
end
