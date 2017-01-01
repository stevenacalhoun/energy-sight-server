namespace :fix_data do
  # Fix capitalization errors
  task song_artist_capitalization: :environment do
    puts "Fixing song/artist capitalization discrepency"
    songsRemoved = 0
    duplicateSongs = Song.select('lower(artist) as artist','lower(title) as title').group('lower(artist)','lower(title)').having("count(*) > 1")

    i = 0
    duplicateSongs.each do |duplicateSong|
      if i%100 == 0
        puts "Progress: " + i.to_s + "/" + duplicateSongs.length.to_s
      end
      i += 1

      # Get all songs matching this artist/title combo
      matchingSongs = Song.select(:id,:albumArtLink).where("lower(artist) = ? and lower(title) = ?", duplicateSong.artist, duplicateSong.title).order(popularity: :desc)

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
    end
    puts "Removed " + songsRemoved.to_s + " songs"
    puts "Kept " + j.to_s + " songs"
  end

  # Fix missing articles, remove "featuring" etc.
  task artist_names: :environment do
    puts "Normalizing artists' names"

    # Create from database
    artists = createArtistDictFromDb()
    correctNames(artistChanges)

    # # Or create from file
    # artistChanges = createArtistDictFromFile('artist_names.txt')

    # # Write to file for inspection
    # open('artist_names2.txt', 'w') { |f|
    #   artistChanges.keys.each do |artist|
    #     line = artist + " => " + artistChanges[artist]
    #     f.puts line
    #   end
    # }

    # Update DB
    i = 0
    artistChanges.keys.each do |artist|
      i = i + 1
      if (i % 1000) == 0
        puts "Progress: " + i.to_s + "/" + artistChanges.keys.length.to_s
      end
      if artist != artistChanges[artist]
        artistsMatch = Song.select(:artist).where(artist: artist).update_all(artist: artistChanges[artist])
      end
    end
    puts "Changed " + i.to_s + " artist names"
  end

  # Remove duplicate songs based on spotify_id
  task duplicate_songs_on_id: :environment do
    puts "Removing duplicate songs"
    removedSongs = 0
    duplicateSongs = Song.select(:spotify_id).where.not(spotify_id: nil).group(:spotify_id).having("count(*) > 1")

    i = 0
    duplicateSongs.each do |duplicateSong|
      if i%100 == 0
        puts "Progress: " + i.to_s + "/" + duplicateSongs.length.to_s
      end
      i += 1

      # Get all songs matching this artist/title combo
      matchingSongs = Song.select(:id).where(spotify_id: duplicateSong.spotify_id)
      trueSong = matchingSongs.first

      matchingSongs.each do |matchingSong|
        if matchingSong.id != trueSong.id
          # Update entries to "true song" id
          topChartSongEntries = TopChart.select(:id, :song_id).where(song_id: matchingSong.id).update_all(song_id: trueSong.id)

          # Delete matching song
          Song.destroy(matchingSong.id)
          removedSongs += 1
        end
      end
    end
    puts "Removed " + removedSongs.to_s + " duplicate songs"
  end

  # Remove duplicate songs based on title/artist
  task duplicate_songs: :environment do
    puts "Removing duplicate songs"

    removedSongs = 0
    duplicateSongs = Song.select(:artist,:title).group(:artist,:title).having("count(*) > 1")

    i = 0
    duplicateSongs.each do |duplicateSong|
      if i%100 == 0
        puts "Progress: " + i.to_s + "/" + duplicateSongs.length.to_s
      end
      i += 1

      # Get all songs matching this artist/title combo
      matchingSongs = Song.select(:id,:albumArtLink).where(artist: duplicateSong.artist, title: duplicateSong.title)

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
          # Update entries to "true song" id
          topChartSongEntries = TopChart.select(:id, :song_id).where(song_id: matchingSong.id).update_all(song_id: trueSong.id)

          # Delete matching song
          Song.destroy(matchingSong.id)
          removedSongs += 1
        end
      end
    end
    puts "Removed " + removedSongs.to_s + " duplicate songs"
  end
end

def correctNames(artistChanges)
  # Words to split on
  splitAndKeepWords = [
    " and ",
    " And ",
    " & ",
    "/",
    " feat ",
    " Feat ",
    " feat.",
    " Feat.",
    " feat. ",
    " Feat. ",
    " ft ",
    " Ft ",
    " ft.",
    " Ft.",
    " ft. ",
    " Ft. ",
    " featured ",
    " Featured ",
    " featuring ",
    " Featuring "
  ]

  # Split on each word
  splitAndKeepWords.each do |word|
    artistChanges = splitAndKeep(artistChanges, word).clone
  end

  articles = {
    " the " => " ",
    " The " => " ",
    "The " => "",
    "the " => ""
  }
  artistChanges = fixArticles(artistChanges, articles)

  return artistChanges
end

def createArtistDictFromFile(filename)
  artists = Hash.new
  open(filename, 'r') do |f|
    f.each_line do |line|
      origArtist = line.split(" => ").first
      changeArtist = line.split(" => ").last.sub("\n", "")
      artists[origArtist] = changeArtist
    end
  end
  return artists
end

def createArtistDictFromDb()
  # Get entries
  artists = Song.select(:artist).uniq.order(:artist)
  artistChanges = Hash.new
  artists.each do |artist|
    artistChanges[artist.artist] = artist.artist
  end

  return artists
end

def fixArticles(artists, articles)
  articleFreeDict = Hash.new

  # Remove all articles
  artists.keys.each do |artist|
    # Remove all articles
    articleFree = artist
    articles.keys.each do |article|
      articleFree = articleFree.sub(article, articles[article])
    end

    # Add only if something has changed
    if articleFree != artist
      articleFreeDict[articleFree] = artist
    end
  end

  # Replace each article-less artist with the article version
  artists.keys.each do |artist|
    if articleFreeDict.keys.include? artists[artist]
      puts artists[artist]
      puts articleFreeDict[artists[artist]]
      puts ""
      artists[artist] = articleFreeDict[artists[artist]]
    end
  end

  return artists
end

def splitAndKeep(artists, splitWord)
  splitArtistsDict = Hash.new
  splitArtists = []

  # Split on word
  artists.keys.each do |artist|
    splitArtist = artists[artist].split(splitWord).first
    splitArtistsDict[artist] = splitArtist
    splitArtists.append(splitArtist)
  end

  # If the left of the word is an artist then keep it
  artists.keys.each do |artist|
    if (artists.keys.include? splitArtistsDict[artist]) == false
      splitArtistsDict[artist] = artist
    end
  end

  return splitArtistsDict
end
