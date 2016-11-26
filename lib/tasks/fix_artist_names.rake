namespace :fix_artist_names do
  task fix: :environment do
    # artists = createArtistDictFromDb()
    artistChanges = createArtistDictFromFile('artist_names.txt')

    # correctNames(artistChanges)

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
    " feat.",
    " Feat ",
    " Feat.",
    " ft ",
    " ft.",
    " Ft ",
    " Ft.",
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
