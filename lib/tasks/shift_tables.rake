namespace :shift_tables do
  task shift: :environment do
    # Update all None spotify ids to nil
    Hot100Entry.where(spotifyID: "None").update_all(spotifyID: nil)

    # Find all unqiue songs and add each one
    songs = Hot100Entry.select(:artist, :title, :spotifyID).uniq
    i = 0;
    songCreates = []
    songs.each do |song|
      if i % 10000 == 0
        puts "Configuring song " + i.to_s + "/" + songs.length.to_s
      end
      songCreates.append({:spotify_id => song.spotifyID, :title => song.title, :artist => song.artist})
      i = i + 1
    end
    puts "Creating songs, no progress meter"
    Song.create(songCreates)

    # Get all songs
    allSongs = Song.all

    # For every song, find all hot 100 entries referencing it
    i = 0
    topChartCreates = []
    allSongs.each do |song|
      if i % 100 == 0
        puts "Configuring top chart entries for song " + i.to_s + "/" + allSongs.length.to_s
      end
      i = i + 1
      hot100entries = Hot100Entry.where(artist: song.artist, title: song.title, spotifyID: song.spotify_id)

      # Add each hot100 entry to top_charts
      hot100entries.each do |entry|
        topChartCreates.append({
          song_id: song.id,
          rank: entry.rank,
          change: entry.change,
          last_pos: entry.lastPos,
          weeks: entry.weeks,
          chart_week: entry.chartWeek,
          country: entry.country
          })
      end
    end
    puts "Creating top chart entries, no progress meter"
    TopChart.create(topChartCreates)
  end
end
