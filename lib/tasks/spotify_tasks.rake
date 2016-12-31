require 'rspotify'

namespace :spotify do
  # Search for songs to fill in missing ids
  task get_missing_ids: :environment do
    matched = 0
    uk_searched = 0
    couldnt_find = 0
    already_populated = 0
    num_total = Hot100Entry.count
    puts "Total: #{num_total} records to process."
    puts "Progress meter is only a lower bound (it doesn't count some skipped records)."
    error_count = 0
    progress = 0
    uk_search = false
    Hot100Entry.select(:title, :artist, :spotifyID, :spotifyLink).distinct.all.each do |entry|
      if (entry.spotifyID == 'None' || entry.spotifyID.nil?)
        # Hit API
        begin
          if uk_search
            uk_searched += 1
            search_result = RSpotify::Track.search(entry.title, market: 'GB')
          else
            search_result = RSpotify::Track.search(entry.title, market: 'US')
          end
        rescue RestClient::Exception => e
          puts("Exception encountered: #{e.message}")
          puts("Response: #{e.response}")
          case e.http_code
          # Auth rejected
          when 401
            puts("Retrying auth...")
            RSpotify::authenticate(ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_SECRET"])
            retry
          # Not found
          when 404
            puts("Retrying...")
            retry
          else
              puts("Sleeping for 60 then retrying.")
              sleep 60
              puts("Retrying...")
              retry
          end
        end
        # Can't find song
        if (search_result.empty? || search_result.nil?)
          if uk_search
            uk_search = false
            couldnt_find += 1
            next
          else
            uk_search = true
            redo
          end
        end
        found = false
        search_result.each do |track|
          track.artists.map{ |a| a.name }.each do |artist_name|
            if entry.artist.include?(artist_name)
              found = true
              entry.spotifyID = track.id
              entry.spotifyLink = track.href
              entry.save
              matched += Hot100Entry.where(title: entry.title, artist: entry.artist).update_all(spotifyID: entry.spotifyID, spotifyLink: entry.spotifyLink)
              break
            end
          end
          if found
            break
          end
        end
        if found
          uk_search = false
        elsif uk_search
          couldnt_find += 1
        else
          uk_search = true
          redo
        end
      else
        already_populated += 1
      end
      if (matched + couldnt_find) >= (num_total - already_populated)*progress/100
        puts "#{progress}%: #{matched} matches, #{couldnt_find} tracks that cannot be found, #{already_populated} tracks already populated. #{uk_searched} tracks were looked for in GB."
        progress += 1
      end
    end
    puts "Population Complete!"
  end

  # Previw url for song
  task get_song_preview_url: :environment do
    # Get all songs that have a spotify id and no preview_url
    songs = Song.select(:id, :spotify_id).where.not(spotify_id: nil).where(preview_url: nil)

    i = 0
    batch = []
    urlsAdded = 0
    songs.each do |song|
      # Print progress
      if i%1000 == 0
        puts "Progress: " + i.to_s + "/" + songs.length.to_s
      end
      i = i + 1

      # Push spotify_ids until we have 50
      batch.push(song.spotify_id)
      if batch.length % 50 == 0
        # Search 50 tracks at a time
        searched_tracks = RSpotify::Track.find(batch)
        searched_tracks.each do |track|
          # Track not found
          if track != nil
            # Track doesn't have preview url
            if track.preview_url != nil
              # Update entry
              Song.where(spotify_id: track.id).update_all(preview_url: track.preview_url)
              urlsAdded = urlsAdded + 1
            end
          end
        end

        # Restart batching
        batch = []
      end
    end

    # Last batch
    searched_tracks = RSpotify::Track.find(batch)
    searched_tracks.each do |track|
      # Track not found
      if track != nil
        # Track doesn't have preview url
        if track.preview_url != nil
          # Update entry
          Song.where(spotify_id: track.id).update_all(preview_url: track.preview_url)
          urlsAdded = urlsAdded + 1
        end
      end
    end

    puts "Added " + urlsAdded.to_s + " preview URLs"
  end

  # Get song's genres
  task get_genre: :environment do
    categories = [["rock"], ["pop"], ["r&b"], ["dance", "disco", "electronic"],
      ["rap", "hip", "hop"], ["alternative"], ["blues", "soul"], ["country", "folk"], ["classic"],
      ["jazz"]]
    matched = 0
    no_id = 0
    no_track = 0
    no_genre = 0
    blacklist = []
    num_total = Song.count
    puts "Total: #{num_total} records to process."
    progress = 0
    id_batch_50 = Array.new # API accepts 50 IDs at a time for tracks
    Song.select(:spotify_id, :artist, :genre).distinct.all.each do |entry|
      if (entry.spotify_id.nil? || entry.spotify_id == "None")
        no_id += 1
      elsif entry.genre.nil?
        unless blacklist.include? entry.artist
          id_batch_50 << entry.spotify_id
        end
      end
      if id_batch_50.length == 50
        begin
          searched_tracks = RSpotify::Track.find(id_batch_50)
          searched_tracks.zip(id_batch_50).each do |track, id|
            if track.nil?
              no_track += 1
            else
              searched_genre = nil
              genre_found = false
              unless (track.artists.nil? || track.artists.empty?)
                # Look for a matching genre for the first artist associated with the song
                # Rest assured the artists are NOT in alphabetical order
                track.artists.first.genres.each do |spotify_genre|
                  categories.each do |category|
                    category.each do |genre_name|
                      if spotify_genre.include?(genre_name)
                        searched_genre = category.first # The first entry of each category is the representative name
                        genre_found = true
                        break # Breaks out of |genre_name|
                      end
                    end
                    if genre_found
                      break # Breaks out of |category|
                    end
                  end
                  if genre_found
                    break # Breaks out of |spotify_genre|
                  end
                end
              end
              if genre_found
                matched += Song.where(artist: entry.artist).where(genre: nil).update_all(genre: searched_genre)
              else
                no_genre += 1
                blacklist << entry.artist
              end
            end
          end
        rescue RestClient::Exception => e
          puts("Exception encountered: #{e.message}")
          puts("Response: #{e.response}")
          case e.http_code
          when 400
            puts("Sleeping for 60 then retrying.")
            sleep 60
            puts("Retrying...")
            retry
          # Auth rejected
          when 401
            puts("Retrying auth...")
            RSpotify::authenticate(ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_SECRET"])
            retry
            # Not found
          when 404
            puts("Retrying...")
            retry
          else
            puts("Sleeping for 60 then retrying.")
            sleep 60
            puts("Retrying...")
            retry
          end
        end
        id_batch_50 = Array.new
      end
      if (matched + no_id + no_track) >= num_total*progress/100
        puts "#{progress}%: #{matched} matches, #{no_id} tracks w/o ID, #{no_track} tracks w/o Spotify entries (but with non-null and non-\"None\" ID), #{no_genre} tracks w/o genre info. #{blacklist.length} artists without genre info."
        progress += 1
      end
    end
    puts "Population Complete!"
  end

  # Get audio features for songs
  task get_song_details: :environment do
    matched = 0
    no_id = 0
    no_track = 0
    no_features = 0
    num_total = 2*Song.count
    puts "Total: #{num_total} records to process (double count for album art and audio features)."
    progress = 0
    id_batch_50 = Array.new # API accepts 50 IDs at a time for tracks
    Song.select(:spotify_id).distinct.all.each do |entry|
      if (entry.spotify_id.nil? || entry.spotify_id == "None")
        no_id += 1
      else
        id_batch_50 << entry.spotify_id
      end
      if id_batch_50.length == 50
        begin
          RSpotify::authenticate(ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_SECRET"])
          searched_tracks = RSpotify::Track.find(id_batch_50)
          searched_tracks.zip(id_batch_50).each do |track, id|
            if track.nil?
              no_track += 1
            else
              matched += Song.where(spotify_id: id).update_all(albumArtLink: (track.album.images.empty? ? nil : track.album.images.first["url"]))
              features = track.audio_features
              if features.nil?
                no_features += 1
              else
                begin
                  matched += Song.where(spotify_id: id).update_all(
                    danceability:     features.danceability,
                    energy:           features.energy,
                    key:              features.key,
                    loudness:         features.loudness,
                    mode:             features.mode,
                    speechiness:      features.speechiness,
                    acousticness:     features.acousticness,
                    instrumentalness: features.instrumentalness,
                    liveness:         features.liveness,
                    valence:          features.valence,
                    tempo:            features.tempo,
                    time_signature:   features.time_signature
                  )
                rescue RestClient::Exception => e
                  if e.http_code == 404
                    no_features += 1
                    puts "Skipping audio_features due to 404 (retrying won't help)."
                  else
                    raise e
                  end
                end
              end
            end
          end
        rescue RestClient::Exception => e
          puts("Exception encountered: #{e.message}")
          puts("Response: #{e.response}")
          case e.http_code
          when 400
            puts("Sleeping for 60 then retrying.")
            sleep 60
            puts("Retrying...")
            retry
          # Auth rejected
          when 401
            puts("Retrying auth...")
            RSpotify::authenticate(ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_SECRET"])
            retry
          # Not found
          when 404
            puts("Retrying...")
            retry
          else
            puts("Sleeping for 60 then retrying.")
            sleep 60
            puts("Retrying...")
            retry
          end
        end
        id_batch_50 = Array.new
      end
      if (matched + no_id + no_track + no_features) >= num_total*progress/100
        puts "#{progress}%: #{matched} matches, #{no_id} tracks w/o ID, #{no_track} tracks w/o Spotify entries (but with non-null and non-\"None\" ID), #{no_features} tracks w/o audio feature info."
        progress += 1
      end
    end
    puts "Population Complete!"
  end
end
