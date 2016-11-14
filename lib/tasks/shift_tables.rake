namespace :table_shift do
  task shift: :environment do
    chartEntries = Hot100Entry.where(country: 'uk').where.not(spotifyID: nil).where.not(spotifyID: "None").limit(10000)

    chartEntries.each do |entry|
      if Song.exists?(:spotifyID => entry.spotifyID)
        @song = Song.where(:spotifyID => entry.spotifyID).first
      else
        @song = Song.create(spotifyID: entry.spotifyID, title: entry.title, artist: entry.artist)
      end

      if TopChart.exists?(:rank => entry.rank, :chartWeek => entry.chartWeek) == false
        @entry = TopChart.new(song_id: @song.id, rank: entry.rank, change: entry.change, peakPos: entry.peakPos, lastPos: entry.lastPos, weeks: entry.weeks, chartWeek: entry.chartWeek, country: entry.country)
        @entry.save
      end
    end
  end
end
