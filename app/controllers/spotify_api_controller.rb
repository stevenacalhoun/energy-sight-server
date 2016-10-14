require 'rspotify'

class SpotifyApiController < ApplicationController
  skip_before_filter  :verify_authenticity_token
  def index
    id = params[:song_id]
    track = RSpotify::Track.find(id)
    render json: track.audio_features
  end

  def create
    ids = params["ids"]
    trackData = []
    tracks = RSpotify::Track.find(ids)

    for @track in tracks do
      @trackInfo = {
        "audio_features": @track.audio_features,
        "info": @track
      }
      trackData.append(@trackInfo)
    end

    render json: trackData
  end
end
