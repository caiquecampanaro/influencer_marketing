module Api
    module V1
      class InfluencerCampaignsController < ApplicationController
        before_action :set_influencer_campaign, only: [:show, :destroy]

        def index
          @influencer_campaigns = InfluencerCampaign.all
          render json: @influencer_campaigns
        end
  
        def show
          render json: @influencer_campaign
        end
  
        def create
          @influencer_campaign = InfluencerCampaign.new(influencer_campaign_params)
  
          if @influencer_campaign.save
            render json: @influencer_campaign, status: :created
          else
            render json: @influencer_campaign.errors, status: :unprocessable_entity
          end
        end
  
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
  