require 'rspotify'

namespace :audiofeatures_populate do
  task all: :environment do
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
