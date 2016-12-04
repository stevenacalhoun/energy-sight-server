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

      # Look up by artist/title combo if spotify ID not present
      if (entry.spotifyID == nil) or (entry.spotifyID == "None")
        @song = Song.where(spotify_id: nil, title: entry.title, artist: entry.artist).first_or_create

      # Look up by spotify ID if pesent
      else
        @song = Song.where(spotify_id: entry.spotifyID, title: entry.title, artist: entry.artist).first_or_create
      end

      # Create new entry
      @entry = TopChart.where(song_id: @song.id, rank: entry.rank, change: entry.change, peak_pos: entry.peakPos, last_pos: entry.lastPos, weeks: entry.weeks, chart_week: entry.chartWeek, country: entry.country).first_or_create
    end
  end
end
