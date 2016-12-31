namespace :task_runner do
  task all: :environment do
    puts "Importing data"
    Rake::Task["import_data:import_csv"].invoke

    puts "Fixing artist names"
    Rake::Task["fix_data:artist_names"].invoke

    puts "Getting missing Spotify IDs from Spotify"
    Rake::Task["spotify:get_missing_ids"].invoke

    puts "Getting audio features from Spotify"
    Rake::Task["spotify:get_audio_features"].invoke

    puts "Getting album artwork from Spotify"
    Rake::Task["spotify:get_album_art_link"].invoke

    puts "Removing duplicate songs"
    Rake::Task["fix_data:duplicate_songs"].invoke

    puts "Getting genre from Spotify"
    Rake::Task["spotify:get_genre"].invoke

    puts "Getting song preview URL from Spotify"
    Rake::Task["spotify:get_song_preview_url"].invoke

    puts "Removing songs with similar capitalizations"
    Rake::Task["fix_data:song_artist_capitalization"].invoke

    puts "Done!"
  end

  task spotify_tasks: :environment do
    puts "Getting missing Spotify IDs from Spotify"
    Rake::Task["spotify:get_missing_ids"].invoke

    puts "Getting audio features from Spotify"
    Rake::Task["spotify:get_audio_features"].invoke

    puts "Getting album artwork from Spotify"
    Rake::Task["spotify:get_album_art_link"].invoke

    puts "Getting genre from Spotify"
    Rake::Task["spotify:get_genre"].invoke

    puts "Getting song preview URL from Spotify"
    Rake::Task["spotify:get_song_preview_url"].invoke
  end

end
