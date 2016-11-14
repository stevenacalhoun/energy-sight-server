class SongInfoController < ApplicationController
  def index
    # Params
    @songIDs = params[:songSpotifyIDs].split(',')

    @results = Hot100Entry.select('artist, title, "spotifyID", "spotifyLink"').where(:spotifyID =>  @songIDs).uniq

    render json: @results
  end
end
