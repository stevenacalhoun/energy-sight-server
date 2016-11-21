namespace :shift_tables do
  task shift: :environment do
    # Get entries
    chartEntries = Hot100Entry.all

    @i = 0;
    chartEntries.each do |entry|
      # Status
      if @i % 10000 == 0
        puts "Progress: #{@i}/#{chartEntries.length}"
      end
      @i = @i + 1

      # Just double check we haven't already entered this one
      if TopChart.exists?(:rank => entry.rank, :chart_week => entry.chartWeek, :country => entry.country) == false
        # Look up by artist/title combo if spotify ID not present
        if (entry.spotifyID == nil) or (entry.spotifyID == "None")
          # Check if song exists by title
          if Song.exists?(:title => entry.title)
            @song = Song.where(:title => entry.title).first
          else
            @song = Song.create(spotify_id: nil, title: entry.title, artist: entry.artist)
          end

        # Look up by spotify ID if pesent
        else
          # Check if song exists by spotify id
          if Song.exists?(:spotify_id => entry.spotifyID)
            @song = Song.where(:spotify_id => entry.spotifyID).first
          else
            @song = Song.create(spotify_id: entry.spotifyID, title: entry.title, artist: entry.artist)
          end
        end

        # Create new entry
        @entry = TopChart.new(song_id: @song.id, rank: entry.rank, change: entry.change, peak_pos: entry.peakPos, last_pos: entry.lastPos, weeks: entry.weeks, chart_week: entry.chartWeek, country: entry.country)
        @entry.save
      end
    end
  end
end
