namespace :duplicate_song_removal do
  task remove: :environment do
    duplicateSongs = Song.select(:artist,:title).group(:artist,:title).having("count(*) > 1")
    puts duplicateSongs.length.to_s + " songs have the same artist and title value"

    j = 0
    duplicateSongs.each do |duplicateSong|
      if j%100 == 0
        puts "Progress: " + j.to_s + "/" + duplicateSongs.length.to_s
      end
      
      puts duplicateSong.artist + ": " + duplicateSong.title

      # Get all songs matching this artist/title combo
      matchingSongs = Song.select(:id).where(artist: duplicateSong.artist, title: duplicateSong.title)

      # Pick the first song as the "true song"
      trueSong = matchingSongs.first
      i = 0
      matchingSongs.each do |matchingSong|
        if matchingSong.id != trueSong.id
          # Update entries to "true song" id
          topChartSongEntries = TopChart.select(:id, :song_id).where(song_id: matchingSong.id).update_all(song_id: trueSong.id)

          # Delete matching song
          Song.destroy(matchingSong.id)
        end
        i = i+1
      end
      j = j+1
    end
  end
end
