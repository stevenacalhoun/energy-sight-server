namespace :task_runner do
  task run_full: :environment do
    puts "Running all tasks"

    # Import data
    Rake::Task["import_data:import_csv"].invoke

    # Getting missing Spotify IDs from Spotify
    Rake::Task["spotify:get_missing_ids"].invoke

    # Set artist/title to spotify artist/title
    Rake::Task["spotify:reset_artist_title"].invoke

    # Get rid of duplicate Spotify ID entries
    Rake::Task["fix_data:duplicate_songs_on_id"].invoke

    # Get spotify info
    Rake::Task["spotify:get_info"].invoke
  end

  task run_with_base: :environment do
    puts "Running tasks after import"

    # Getting missing Spotify IDs from Spotify
    Rake::Task["spotify:get_missing_ids"].invoke

    # Get rid of duplicate Spotify ID entries
    Rake::Task["fix_data:duplicate_songs_on_id"].invoke

    # Get spotify info
    Rake::Task["spotify:get_info"].invoke
  end

  task run_with_all_ids: :environment do
    puts "Running tasks after filling in ids"

    # Get rid of duplicate Spotify ID entries
    Rake::Task["fix_data:duplicate_songs_on_id"].invoke

    # Get spotify info
    Rake::Task["spotify:get_info"].invoke
  end

  task run_get_spotify_tasks: :environment do
    puts "Running tasks after removing duplicate ids"

    # Get spotify info
    Rake::Task["spotify:get_info"].invoke
  end
end
