class ArtistInfoController < ApplicationController
  def index
    render text: 'heyo'
  end
  def show
    artist = params[:artist]
    earliestDate = Date.parse(params[:startDate])
    latestDate = Date.parse(params[:endDate])

    songs = TopChart.select('top_charts.chart_week, top_charts.country, songs.spotify_id, songs.artist, songs.title, top_charts.rank, songs.preview_url, songs.album_art_link').joins(:song).where('top_charts.chart_week' => earliestDate..(latestDate+7)).where('songs.artist' => artist)

    songData = {}
    songs.each do |song|
      if songData.key?(song.title) == false
        songData[song.title] = {
          "spotify_id": song.spotify_id,
          "title": song.title,
          "artist": song.artist,
          "preview_url": song.preview_url,
          "album_art_link": song.album_art_link,
          "dates": []
        }
      end
      songData[song.title][:dates].push({
          "chart_week": song.chart_week,
          "rank": song.rank,
          "country": song.country
        })
    end

    results = flattenDict(songData).sort_by{|obj| obj[:title]}

    render json: results
  end
end

def flattenDict(dict)
  array = []
  dict.each do |key, data|
    array.append(data)
  end
  return array
end
