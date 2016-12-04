class ArtistInfoController < ApplicationController
  def index
    render text: 'heyo'
  end
  def show
    @artist = params[:artist]
    @earliestDate = Date.parse(params[:startDate])
    @latestDate = Date.parse(params[:endDate])


    @results = TopChart.select('top_charts.chart_week, top_charts.country, songs.artist, songs.title, top_charts.rank, songs."albumArtLink"').joins(:song).where('top_charts.chart_week' => @earliestDate..(@latestDate+7)).where('songs.artist' => @artist)

    render json: @results
  end
end
