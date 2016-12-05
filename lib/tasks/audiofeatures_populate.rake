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
    id_batch_100 = Array.new # API accepts 100 IDs at a time for features
    id_batch_50 = Array.new # API accepts 50 IDs at a time for tracks
    Song.select(:spotify_id).distinct.all.each do |entry|
      if (entry.spotify_id.nil? || entry.spotify_id == "None")
        no_id += 1
      else
        id_batch_50 << entry.spotify_id
      end
      if id_batch_50.length == 50
        id_batch_100 += id_batch_50
        do_audio_features = (id_batch_100.length == 100)
        begin
          searched_tracks = RSpotify::Track.find(id_batch_50)
          searched_tracks.zip(id_batch_50).each do |track, id|
            if track.nil?
              no_track += 1
            else
              matched += Song.where(spotify_id: id).update_all(albumArtLink: (track.album.images.empty? ? nil : track.album.images.first["url"]))
            end
          end
          if do_audio_features
            feature_url = "audio-features?ids=#{id_batch_100.join(",")}"
            response = RSpotify.get(feature_url)
            searched_features = response["audio_features"].map { |i| i.nil? ? nil : RSpotify::AudioFeatures.new(i) }
            searched_features.zip(id_batch_100).each do |features, id|
              if features.nil?
                no_features += 1
              else
                Song.where(spotify_id: id).all.each do |match|
                  matched += 1
                  if match.danceability.nil?  
                    begin
                      match.danceability = features.danceability
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for danceability..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  if match.energy.nil?  
                    begin
                      match.energy = features.energy
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for energy..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  if match.key.nil?  
                    begin
                      match.key = features.key
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for key..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  if match.loudness.nil?  
                    begin
                      match.loudness = features.loudness
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for loudness..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  if match.mode.nil?  
                    begin
                      match.mode = features.mode
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for mode..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  if match.speechiness.nil?  
                    begin
                      match.speechiness = features.speechiness
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for speechiness..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  if match.acousticness.nil?  
                    begin
                      match.acousticness = features.acousticness
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for acousticness..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  if match.instrumentalness.nil?  
                    begin
                      match.instrumentalness = features.instrumentalness
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for instrumentalness..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  if match.liveness.nil?  
                    begin
                      match.liveness = features.liveness
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for liveness..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  if match.valence.nil?  
                    begin
                      match.valence = features.valence
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for valence..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  if match.tempo.nil?  
                    begin
                      match.tempo = features.tempo
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for tempo..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  if match.time_signature.nil?  
                    begin
                      match.time_signature = features.time_signature
                    rescue RestClient::Exception => e
                      puts "Exception encountered: #{e.message}"
                      puts "Response: #{e.response}"
                      if e.http_code == 404
                        puts "Skipping 404 for time_signature..."
                      else
                        puts "Retrying..."
                        retry
                      end
                    end
                  end
                  match.save
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
        if do_audio_features
          id_batch_100 = Array.new
        end
      end
      if (matched + no_id + no_track + no_features) >= num_total*progress/100
        puts "#{progress}%: #{matched} matches, #{no_id} tracks w/o ID, #{no_track} tracks w/o Spotify entries (but with non-null and non-\"None\" ID), #{no_features} tracks w/o audio feature info."
        progress += 1
      end
    end
    puts "Population Complete!"
  end
end
