namespace :artist_populate do
  task populate: :environment do
    # Get all entries
    entries = TopChart.select(:id, :song_id)
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
