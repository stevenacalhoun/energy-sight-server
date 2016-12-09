namespace :preview_url do
  task populate: :environment do
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

end
