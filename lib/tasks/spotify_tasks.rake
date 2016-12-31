require 'rspotify'

namespace :spotify do
  # Search for songs to fill in missing ids
  task get_missing_ids: :environment do
    foundIds = 0
    i = 0
    songsWithoutIds = Song.where(spotify_id: nil)

    songsWithoutIds.each do |song|
      if i%100 == 0
        puts "Progress: " + i.to_s + "/" + songsWithoutIds.count.to_s
      end
      # Search by title
      search_results = RSpotify::Track.search(entry.title, market: 'US')

      # Order by popularity
      search_results.sort! {|obj| obj.popularity}.reverse

      if ((search_results.empty? == false) && (search_results != nil))
        # Find the first track with correct artist name
        search_results.each do |track|
          track.artists.each do |artist|
            # Update song with link and ID
            if entry.artist.include?(artist.name)
              entry.spotify_id = track.id
              entry.save

              foundIds += 1
            end
          end
        end
      end
      i += 1
    end
    puts "New found IDs: " + foundIds.to_s
    puts "IDs still missing: " + (songsWithoutIds.count - foundIds).to_s
  end

  # Get song's genres
  task get_genre: :environment do
    # Genre categories
    categories = {
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

    # Counters
    i = 0
    foundGenres = 0

    # Get all songs with spotify ids
    songsWithIds = Song.select(:spotify_id).where.not(spotify_id: nil).where(genre: nil)

    # Batch ids and search 50 at a time
    batch = []
    songsWithIds.each do |song|
      # Print progress
      if i%1000 == 0
        puts "Progress: " + i.to_s + "/" + songs.length.to_s
      end
      i = i + 1

      batch.push(song.spotify_id)
      if batch.length == 50
        searched_tracks = RSpotify::Track.find(batch)
        searched_tracks.each do |track|
          if track != nil
            # Look for a matching genre for the first artist associated with the song
            track.artists.first.genres.each do |spotify_genre|
              categories.each do |genre, genre_options|
                if genre_options.contains(spotify_genre)
                  Song.where(spotify_id: track.id).update_all(genre: genre)
                end
              end
            end
          end
        end
        batch = []
      end
    end

    # Last batch
    searched_tracks = RSpotify::Track.find(batch)
    searched_tracks.each do |track|
      if track != nil
        # Look for a matching genre for the first artist associated with the song
        track.artists.first.genres.each do |spotify_genre|
          categories.each do |genre, genre_options|
            if genre_options.contains(spotify_genre)
              Song.where(spotify_id: track.id).update_all(genre: genre)
            end
          end
        end
      end
    end
    puts "Added genres: " + foundGenres.to_s
    puts "Genres still missing: " + (Song.count - foundGenres).to_s
  end

  # Get album art link
  task get_album_art_link: :environment do
    i = 0
    foundAlbumArtLinks = 0

    # Get all songs with spotify ids
    songsWithIds = Song.select(:spotify_id).where.not(spotify_id: nil).where(album_art_link: nil)

    # Batch 50 ids and search all at once
    batch =[]
    songsWithIds do |song|
      # Print progress
      if i%1000 == 0
        puts "Progress: " + i.to_s + "/" + songs.length.to_s
      end
      i = i + 1

      batch.push(song.spotify_id)
      if batch.length == 50
        searched_tracks = RSpotify::Track.find(batch)
        searched_tracks.each do |track|
          if track != nil
            # Add album art link
            if track.album.images.empty? == false
              Song.where(spotify_id: track.id).update_all(albumArtLink: track.album.images.first["url"])
              foundAlbumArtLinks += 1
            end
          end
        end
        batch = []
      end
    end

    # Last batch
    searched_tracks = RSpotify::Track.find(batch)
    searched_tracks.each do |track|
      if track != nil
        # Add album art link
        if track.album.images.empty? == false
          Song.where(spotify_id: track.id).update_all(albumArtLink: track.album.images.first["url"])
          foundAlbumArtLinks += 1
        end
      end
    end
    puts "Added album art: " + foundAlbumArtLinks.to_s
    puts "Album art still missing: " + (Song.count - foundAlbumArtLinks).to_s
  end

  # Get audio features for songs
  task get_audio_features: :environment do
    i = 0
    foundAudioFeatures = 0

    # Get all songs with spotify ids
    songsWithIds = Song.select(:spotify_id).where.not(spotify_id: nil).where(danceability: nil)

    # Batch 50 ids and search all at once
    batch =[]
    songsWithIds do |song|
      # Print progress
      if i%1000 == 0
        puts "Progress: " + i.to_s + "/" + songs.length.to_s
      end
      i = i + 1
      batch.push(song.spotify_id)

      if batch.length == 50
        searched_tracks = RSpotify::Track.find(batch)
        searched_tracks.each do |track|
          if track != nil
            # Add audio features
            if track.audio_features.nil? == false
              matched += Song.where(spotify_id: track.id).update_all(
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
              foundAudioFeatures += 1
            end
          end
        end
        batch = []
      end
    end

    # Last batch
    searched_tracks = RSpotify::Track.find(batch)
    searched_tracks.each do |track|
      if track != nil
        # Add audio features
        if track.audio_features.nil? == false
          matched += Song.where(spotify_id: track.id).update_all(
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
          foundAudioFeatures += 1
        end
      end
    end
    puts "Added audio features: " + foundAudioFeatures.to_s
    puts "Audio features still missing: " + (Song.count - foundAudioFeatures).to_s
  end

  # Get preview URL
  task get_song_preview_url: :environment do
    i = 0
    foundPreviewUrls = 0

    # Get all songs with a spotify id and no preview_url
    songs = Song.select(:id, :spotify_id).where.not(spotify_id: nil).where(preview_url: nil)

    # Batch 50 ids and search all at once
    batch = []
    songs.each do |song|
      # Print progress
      if i%1000 == 0
        puts "Progress: " + i.to_s + "/" + songs.length.to_s
      end
      i = i + 1

      batch.push(song.spotify_id)
      if batch.length == 50
        # Search 50 tracks at a time
        searched_tracks = RSpotify::Track.find(batch)
        searched_tracks.each do |track|
          if track != nil
            if track.preview_url != nil
              # Update entry
              Song.where(spotify_id: track.id).update_all(preview_url: track.preview_url)
              urlsAdded = urlsAdded + 1
            end
          end
        end
        batch = []
      end
    end

    # Last batch
    searched_tracks = RSpotify::Track.find(batch)
    searched_tracks.each do |track|
      if track != nil
        if track.preview_url != nil
          # Update entry
          Song.where(spotify_id: track.id).update_all(preview_url: track.preview_url)
          foundPreviewUrls += 1
        end
      end
    end
    puts "Added preview urls: " + foundPreviewUrls.to_s
    puts "Prewview urls still missing: " + (Song.count - foundPreviewUrls).to_s
  end
end
