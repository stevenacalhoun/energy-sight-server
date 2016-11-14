require 'date'

class Hot100EntryController < ApplicationController
  def index
    # Params
    @earliestDate = Date.parse(params[:startDate])
    @latestDate = Date.parse(params[:endDate])
    @rank = params[:minRank]

    @results = Hot100Entry.select('"chartWeek", artist, rank').where(:chartWeek =>  @earliestDate..(@latestDate+7)).where(:country => @country)
    .where("rank <= "+@rank.to_s)

    render json: @results
  end

  def show
    # Params
    @earliestDate = Date.parse(params[:startDate])
    @latestDate = Date.parse(params[:endDate])
    @country = params[:country]
    @rank = params[:minRank]
    @artist = params[:artist]

    puts @earliestDate
    puts @latestDate
    @results = TopChart.select('"chartWeek", songs.artist, songs.title, top_charts.rank').where("chartWeek" =>  @earliestDate..(@latestDate+7))#.joins(:song)#.where("top_charts.rank <= "+@rank.to_s)

    # @results = Hot100Entry.select('"chartWeek", artist, title, rank').where(:chartWeek =>  @earliestDate..(@latestDate+7)).where("rank <= "+@rank.to_s)

    # if @artist != "all"
    #   @results = @results.where(:artist => @artist)
    # end
    # if @country != "both"
    #   @results = @results.where(:country => @country)
    # end

    render json: @results
  end
end
