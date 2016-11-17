namespace :shift_tables do
  task shift: :environment do
    # Get entries
    # chartEntries = Hot100Entry.where(country: 'us').where.not(spotifyID: nil).where.not(spotifyID: "None").limit(10000)
    chartEntries = Hot100Entry.all

    @i = 0;
    chartEntries.each do |entry|
      # Status
      if @i % 10000 == 0
        puts "Progress: #{@i}/#{chartEntries.length}"
      end
      @i = @i + 1

      # Missing spotify ID
      if (entry.spotifyID == nil) or (entry.spotifyID == "None")
        # Check if song exists by title
        if Song.exists?(:title => entry.title)
          @song = Song.where(:title => entry.title).first
        else
          @song = Song.create(spotify_id: nil, title: entry.title, artist: entry.artist)
        end

      # Present spotify ID
      else
        # Check if song exists by spotify id
        if Song.exists?(:spotify_id => entry.spotifyID)
          @song = Song.where(:spotify_id => entry.spotifyID).first
        else
          @song = Song.create(spotify_id: entry.spotifyID, title: entry.title, artist: entry.artist)
        end
      end

      # Just double check we haven't already entered this one
      if TopChart.exists?(:rank => entry.rank, :chart_week => entry.chartWeek) == false
        # Create new entry
        @entry = TopChart.new(song_id: @song.id, rank: entry.rank, change: entry.change, peak_pos: entry.peakPos, last_pos: entry.lastPos, weeks: entry.weeks, chart_week: entry.chartWeek, country: entry.country)
        @entry.save
      end
    end
  end
end
