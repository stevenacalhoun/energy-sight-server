require 'rspotify'

namespace :spotify do
  # Search for songs to fill in missing ids
  task get_missing_ids: :environment do
    puts "Filling in missing Spotify IDs"

    songsWithoutIds = Song.where(spotify_id: nil).shuffle
    foundIds = 0

    i = 0
    startTime = Time.now
    songsWithoutIds.each do |song|
      printProgressMessage(i, songsWithoutIds.count, 1000, startTime)
      i += 1

      # Search by title
      search_results = RSpotify::Track.search(song.title)

      # Order by popularity
      search_results.sort! {|obj| obj.popularity}.reverse

      if ((search_results.empty? == false) && (search_results != nil))
        # Find the first track with correct artist name
        search_results.each do |track|
          if track.artists[0].name.downcase.include? song.artist.downcase || track.artists[0].name.downcase == song.artist.downcase
            song.spotify_id = track.id
            song.save

            foundIds += 1
          end
        end
      end
    end
    puts "New found IDs: " + foundIds.to_s
    puts "IDs still missing: " + (songsWithoutIds.count - foundIds).to_s
  end

  task :get_specific_spotify_id, [:id] do |t, args|
    puts "Filling in missing Spotify IDs"

    song = Song.find(args[:id])

    # Find spotify results
    search_results = RSpotify::Track.search(song.title)
    search_results.sort! {|obj| obj.popularity}.reverse

    if ((search_results.empty? == false) && (search_results != nil))
      # Find the first track with correct artist name
      search_results.each do |track|
        if track.artists[0].name.downcase.include? song.artist.downcase || track.artists[0].name.downcase == song.artist.downcase
          song.spotify_id = track.id
          song.save
        end
      end
    end
  end

  # Set artist/title to the artist/title on Spotify
  task reset_artist_title: :environment do
    puts "Reseting artist/title to Spotify artist/ttile"

    # Get all songs with spotify ids
    songsWithIds = Song.select(:spotify_id).where.not(spotify_id: nil)

    # Batch ids and search 50 at a time
    batch = []
    i = 0
    startTime = Time.now
    songsWithIds.each do |song|
      # Print progress
      printProgressMessage(i, songsWithIds.length, 1000, startTime)
      i += 1

      batch.push(song.spotify_id)
      if batch.length == 50
        searched_tracks = RSpotify::Track.find(batch)
        searched_tracks.each do |track|
          if track != nil
            # Reset info for track
            resetArtistTitle(track)
          end
        end
        batch = []
      end
    end

    # Last batch
    searched_tracks = RSpotify::Track.find(batch)
    searched_tracks.each do |track|
      if track != nil
        # Reset info for track
        resetArtistTitle(track)
      end
    end
  end

  # Get track info
  task :get_info, [:max_count] => :environment do |t, args|
    puts "Retrieving track info from Spotify"

    # Get all songs with spotify ids
    songsWithIds = Song.select(:spotify_id,:spotify_search_count).where.not(spotify_id: nil).where("spotify_search_count < ?", args[:max_count])
    puts "Getting info for " + songsWithIds.length.to_s + " songs"

    # Batch ids and search 50 at a time
    batch = []
    i = 0
    startTime = Time.now
    songsWithIds.each do |song|
      # Print progress
      i += 1

      song = song.increment(:spotify_search_count)
      result = song.save

      batch.push(song.spotify_id)
      if batch.length == 50
        # RSpotify::authenticate(ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_SECRET"])
        searched_tracks = RSpotify::Track.find(batch)
        searched_tracks.each do |track|
          if track != nil
            # Fill in all info
            getSpotifyInfo(track)
          end
        end
        printProgressMessage(i, songsWithIds.length, 1000, startTime)
        batch = []
      end
    end

    # Last batch
    searched_tracks = RSpotify::Track.find(batch)
    searched_tracks.each do |track|
      if track != nil
        # Fill in all info
        getSpotifyInfo(track)
      end
    end
  end
end

def resetArtistTitle(track)
  updatedSongs = Song.where(spotify_id: track.id)
  updatedSongs.update_all(artist: track.artists[0].name, title: track.name)
  updatedSongs.each do |updatedSong|
    TopChart.where(song_id:updatedSong.id).update_all(artist:updatedSong.artist)
  end
end

def getSpotifyInfo(track)
  # getGenre(track)
  getAlbumArtLink(track)
  # getAudioFeatures(track)
  getSongPreviewUrl(track)
end

def getGenre(track)
  # Genre categories
  genreCategories = {
    "rock": ["rock"],
    "pop": ["pop"],
    "r&b": ["r&b"],
    "dance": ["dance", "disco", "electronic"],
    "rap": ["rap", "hip", "hop"],
    "alternative": ["alternative"],
    "blues": ["blues", "soul"],
    "country": ["country", "folk"],
    "classic": ["classic"],
    "jazz": ["jazz"]
  }

  # Look for a matching genre for the first artist associated with the song
  track.artists.first.genres.each do |spotify_genre|
    genreCategories.each do |genre, genre_options|
      if genre_options.include? spotify_genre
        Song.where(spotify_id: track.id).update_all(genre: genre)
      end
    end
  end
end

def getAlbumArtLink(track)
  if track.album.images.empty? == false
    Song.where(spotify_id: track.id).update_all(album_art_link: track.album.images.first["url"], popularity: track.popularity)
  end
end

def getAudioFeatures(track)
  features = track.audio_features
  if features.nil? == false
    Song.where(spotify_id: track.id).update_all(
      danceability:     track.audio_features.danceability,
      energy:           track.audio_features.energy,
      key:              track.audio_features.key,
      loudness:         track.audio_features.loudness,
      mode:             track.audio_features.mode,
      speechiness:      track.audio_features.speechiness,
      acousticness:     track.audio_features.acousticness,
      instrumentalness: track.audio_features.instrumentalness,
      liveness:         track.audio_features.liveness,
      valence:          track.audio_features.valence,
      tempo:            track.audio_features.tempo,
      time_signature:   track.audio_features.time_signature
    )
  end
end

def getSongPreviewUrl(track)
  if track.preview_url != nil
    Song.where(spotify_id: track.id).update_all(preview_url: track.preview_url)
  end
end

def printProgressMessage(current, total, increment, startTime)
  if current%1 == 0
    currentTime = Time.now
    elapsedTimeSeconds = currentTime - startTime
    elapsedTime = Time.at(elapsedTimeSeconds).utc.strftime("%H:%M:%S")

    timeRemainingSeconds = (((total/(current+1))*(elapsedTimeSeconds))-elapsedTimeSeconds)
    timeRemaining = Time.at(timeRemainingSeconds).utc.strftime("%H:%M:%S")

    print (((current+1)/total)*100).round(2).to_s + "% complet, elapsed time " + elapsedTime.to_s + ", estimated time remaining " + timeRemaining.to_s + ")" + "\r"
    $stdout.flush
  end
end
