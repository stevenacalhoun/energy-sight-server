require 'rspotify'

namespace :genre_populate do
  task all: :environment do
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
end
