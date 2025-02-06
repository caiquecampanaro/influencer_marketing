module Api
  module V1
    class InfluencersController < ApplicationController
      before_action :set_influencer, only: [:show, :update, :destroy]
  
      def index
        @influencers = Influencer.all
        render json: @influencers
      end
  
      def show
        render json: @influencer
      end
  
      def create
        @influencer = Influencer.new(influencer_params)
  
        if @influencer.save
          render json: @influencer, status: :created
        else
          render json: @influencer.errors, status: :unprocessable_entity
        end
      end
  
      def update
        if @influencer.update(influencer_params)
          render json: @influencer
        else
          render json: @influencer.errors, status: :unprocessable_entity
        end
      end
  
      def destroy
        @influencer.destroy
        head :no_content
      end

      def sync
        response = Faraday.get('https://jsonplaceholder.typicode.com/users')

        if response.status == 200
          influencers_data = JSON.parse(response.body)

          platforms = ['Instagram', 'TikTok', 'YouTube']

          influencers_data.each do |influencer_data|
            influencer = Influencer.find_or_initialize_by(username: influencer_data['username'])
            
            influencer.name = influencer_data['name']
            influencer.username = influencer_data['username']
            influencer.platform = platforms.sample
            influencer.followers = rand(1000..100000)
            influencer.email = influencer_data['email']

            influencer.save if influencer.changed?
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
