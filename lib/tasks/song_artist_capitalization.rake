namespace :song_artist_capitalization do
  task remove: :environment do
    songsRemoved = 0
    duplicateSongs = Song.select('lower(artist) as artist','lower(title) as title').group('lower(artist)','lower(title)').having("count(*) > 1")

    j = 0
    duplicateSongs.each do |duplicateSong|
      if j%100 == 0
        puts "Progress: " + j.to_s + "/" + duplicateSongs.length.to_s
      end

      # Get all songs matching this artist/title combo
      matchingSongs = Song.select(:id,:albumArtLink).where("lower(artist) = ? and lower(title) = ?", duplicateSong.artist, duplicateSong.title)

      # Pick the song with album art link as the "true song"
      trueSong = nil
      matchingSongs.each do |matchingSong|
        if matchingSong.albumArtLink != nil
          trueSong = matchingSong
        end
      end

      # Or just take the first one if no song has album art
      if trueSong == nil
        trueSong = matchingSongs.first
      end

      matchingSongs.each do |matchingSong|
        if matchingSong.id != trueSong.id
          songsRemoved = songsRemoved + 1

          # Update entries to "true song" id
          topChartSongEntries = TopChart.select(:id, :song_id).where(song_id: matchingSong.id).update_all(song_id: trueSong.id)

          # Delete matching song
          Song.destroy(matchingSong.id)
        end
      end
      j = j+1
    end
    puts "Removed " + songsRemoved.to_s + " songs"
    puts "Kept " + j.to_s + " songs"
  end
end
