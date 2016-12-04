require 'rspotify'

namespace :spotifyid_populate do
  task all: :environment do
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
          if (track.artists.map{|a| a.name}.include?(entry.artist))
            found = true
            entry.spotifyID = track.id
            entry.spotifyLink = track.href
            entry.save
            replaced_ids = 0
            Hot100Entry.where(title: entry.title, artist: entry.artist).all.each do |dupe|
              dupe.spotifyID = entry.spotifyID
              dupe.spotifyLink = entry.spotifyLink
              dupe.save
              matched += 1
            end
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
end
