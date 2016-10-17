require 'date'

class Hot100EntryController < ApplicationController
  skip_before_filter  :verify_authenticity_token
  def index
    render text: "heyo"
  end

  def show
    render text: "heyo" + params[:id].to_s
  end

  def create
    # Params
    @earliestDate = Date.parse(params["earliestDate"])
    @latestDate = Date.parse(params["latestDate"])
    @country = params["country"]

    @results = {}

    @results = Hot100Entry.select('"chartWeek", artist').where(:chartWeek =>  @earliestDate..(@latestDate+7)).where(:country => @country)

    render json: @results
  end
end
