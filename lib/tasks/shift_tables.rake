namespace :shift_tables do
  task shift: :environment do
    # Update all None spotify ids to nil
    # Hot100Entry.where(spotifyID: "None").update_all(spotifyID: nil)

    # Find all unqiue songs and add each one
    # songs = Hot100Entry.select(:artist, :title, :spotifyID).uniq
    # i = 0;
    # songCreates = []
    # songs.each do |song|
    #   if i % 10000 == 0
    #     puts "Configuring song " + i.to_s + "/" + songs.length.to_s
    #   end
    #   songCreates.append({:spotify_id => song.spotifyID, :title => song.title, :artist => song.artist})
    #   i = i + 1
    # end
    # Song.create(songCreates)

    # Get all songs
    allSongs = Song.all
    # allHot100 = Hot100Entry.all


    # For every song, find all hot 100 entries referencing it
    i = 0
    topChartCreates = []
    allSongs.each do |song|
      if i % 100 == 0
        puts "Adding top chart entries for song " + i.to_s + "/" + allSongs.length.to_s
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
    TopChart.create(topChartCreates)

  #   # Get entries
  #   chartEntries = Hot100Entry.all
  #
  #   @i = 0;
  #   chartEntries.each do |entry|
  #     # Status
  #     if @i % 10000 == 0
  #       puts "Progress: #{@i}/#{chartEntries.length}"
  #     end
  #     @i = @i + 1
  #
  #     # Look up by artist/title combo if spotify ID not present
  #     if (entry.spotifyID == nil) or (entry.spotifyID == "None")
  #       @song = Song.where(spotify_id: nil, title: entry.title, artist: entry.artist).first_or_create
  #
  #     # Look up by spotify ID if pesent
  #     else
  #       @song = Song.where(spotify_id: entry.spotifyID, title: entry.title, artist: entry.artist).first_or_create
  #     end
  #
  #     # Create new entry
  #     @entry = TopChart.where(song_id: @song.id, rank: entry.rank, change: entry.change, peak_pos: entry.peakPos, last_pos: entry.lastPos, weeks: entry.weeks, chart_week: entry.chartWeek, country: entry.country).first_or_create
  #   end
  end
end
