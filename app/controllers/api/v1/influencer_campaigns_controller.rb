module Api
    module V1
      class InfluencerCampaignsController < ApplicationController
        before_action :set_influencer_campaign, only: [:show, :destroy]
  
        # List all influencer campaigns
        def index
          @influencer_campaigns = InfluencerCampaign.all
          render json: @influencer_campaigns
        end
  
        # Show a specific influencer campaign
        def show
          render json: @influencer_campaign
        end
  
        # Create a new influencer campaign (link influencer with campaign)
        def create
          @influencer_campaign = InfluencerCampaign.new(influencer_campaign_params)
  
          if @influencer_campaign.save
            render json: @influencer_campaign, status: :created
          else
            render json: @influencer_campaign.errors, status: :unprocessable_entity
          end
        end
  
        # Delete an influencer campaign association
        def destroy
          @influencer_campaign.destroy
          head :no_content
        end
  
        private
  
        def set_influencer_campaign
          @influencer_campaign = InfluencerCampaign.find(params[:id])
        end
  
        def influencer_campaign_params
          params.require(:influencer_campaign).permit(:influencer_id, :campaign_id, :custom_metrics)
        end
      end
    end
  end
  