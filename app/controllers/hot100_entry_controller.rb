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
    @earliestDate = Date.parse(params["earliestDate"])
    @latestDate = Date.parse(params["latestDate"])

    @results = {}
    if @earliestDate == @latestDate then
      @results = Hot100Entry.where(chartWeek: @earliestDate.to_s)
    else
      @currentWeek = @earliestDate
      while @currentWeek <= @latestDate
        @weekResults = Hot100Entry.where(chartWeek: @earliestDate.to_s)
        @results[@currentWeek] = @weekResults

        @currentWeek = @currentWeek + 7
      end
    end
    render json: @results
  end
end
