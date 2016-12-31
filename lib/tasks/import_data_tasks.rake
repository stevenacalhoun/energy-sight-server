namespace :import_data do
  # Import raw data into hot100 table
  task import_csv: :environment do
    importCountryData('us')
    importCountryData('uk')
  end

  # Split hot100 to songs and top_charts
  task split_data: :environment do
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

  # Add artist to Top Chart
  task add_artist_to_top_chart: :environment do
    # Get all entries
    entries = TopChart.select(:id, :song_id, :artist).where(artist: nil)
    i = 0
    entries.each do |entry|
      # Print progress
      if i%1000 == 0
        puts "Progress: " + i.to_s + "/" + entries.length.to_s
      end
      i = i + 1

      # Get corresponding song and add artist to entry
      songEntry = Song.select(:artist).where(id: entry.song_id)
      entry.update(artist: songEntry[0].artist)
    end
  end
end

def importCountryData(country)
  csv_text = File.read('data/'+country+'.csv')
  csv = CSV.parse(csv_text)

  i = 0
  csv.each do |row|
    if i % 10000 == 0
      puts "Progress: " + i.to_s + "/" + csv.length.to_s
    end

    # Add each entry
    Hot100Entry.create(title: row[0], artist: row[1], peakPos: row[2], lastPos: row[3], weeks: row[4], rank: row[5], change: row[6], spotifyID: row[7], spotifyLink: row[8], videoLink: row[9], chartWeek: row[10], country: country)
    i = i+1
  end
end
