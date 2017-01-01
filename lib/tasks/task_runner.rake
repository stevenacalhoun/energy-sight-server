namespace :task_runner do
  task all: :environment do
    puts "Running all tasks"

    # Import data
    Rake::Task["import_data:import_csv"].invoke

    # Fixing artist names
    Rake::Task["fix_data:artist_names"].invoke

    # Getting missing Spotify IDs from Spotify
    Rake::Task["spotify:get_missing_ids"].invoke

    # Getting audio features from Spotify
    Rake::Task["spotify:get_audio_features"].invoke

    # Getting album artwork from Spotify
    Rake::Task["spotify:get_album_art_link"].invoke

    # Removing duplicate songs
    Rake::Task["fix_data:duplicate_songs"].invoke

    # Getting genre from Spotify
    Rake::Task["spotify:get_genre"].invoke

    # Getting song preview URL from Spotify
    Rake::Task["spotify:get_song_preview_url"].invoke

    # Removing songs with similar capitalizations
    Rake::Task["fix_data:song_artist_capitalization"].invoke

    puts "Finished all tasks"
  end

  task spotify_tasks: :environment do
    puts "Running all Spotify tasks"

    # Getting missing Spotify IDs from Spotify
    Rake::Task["spotify:get_missing_ids"].invoke

    # Getting audio features from Spotify
    Rake::Task["spotify:get_audio_features"].invoke

    # Getting album artwork from Spotify
    Rake::Task["spotify:get_album_art_link"].invoke

    # Getting genre from Spotify
    Rake::Task["spotify:get_genre"].invoke

    # Getting song preview URL from Spotify
    Rake::Task["spotify:get_song_preview_url"].invoke

    puts "Finished all Spotify tasks"
  end

end
