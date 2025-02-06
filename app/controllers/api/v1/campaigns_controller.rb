module Api
    module V1
      class CampaignsController < ApplicationController
        before_action :set_campaign, only: [:show, :update, :destroy]
  
        # List all campaigns
        def index
          @campaigns = Campaign.all
          render json: @campaigns
        end
  
        # Show a specific campaign
        def show
          render json: @campaign
        end
  
        # Create a new campaign
        def create
          @campaign = Campaign.new(campaign_params)
  
          if @campaign.save
            render json: @campaign, status: :created
          else
            render json: @campaign.errors, status: :unprocessable_entity
          end
        end
  
        # Update a campaign
        def update
          if @campaign.update(campaign_params)
            render json: @campaign
          else
            render json: @campaign.errors, status: :unprocessable_entity
          end
        end
  
        # Delete a campaign
        def destroy
          @campaign.destroy
          head :no_content
        end
  
        private
  
        def set_campaign
          @campaign = Campaign.find(params[:id])
        end
  
        def campaign_params
          params.require(:campaign).permit(:name, :budget, :start_date, :end_date)
        end
      end
    end
  end
  