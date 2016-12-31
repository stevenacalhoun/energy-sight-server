namespace :task_runner do
  task all: :environment do
    # puts "Importing data"
    # Rake::Task["import_data:import_csv"].invoke
    #
    # puts "Shifting Data"
    # Rake::Task["import_data:split_data"].invoke
    #
    # puts "Adding artist to top_charts"
    # Rake::Task["import_data:add_artist_to_top_chart"].invoke
    #
    # puts "Fixing artist names"
    # Rake::Task["fix_data:artist_names"].invoke
    #
    # puts "Hitting API for missing Spotify IDs"
    # Rake::Task["spotify:get_missing_ids"].invoke
    #
    # puts "Hitting API for album artwork, and audio features"
    # Rake::Task["spotify:get_song_details"].invoke
    #
    # puts "Removing duplicate songs"
    # Rake::Task["fix_data:duplicate_songs"].invoke
    #
    # puts "Adding genre"
    # Rake::Task["spotify:get_genre"].invoke
    #
    # puts "Adding Preview URL"
    # Rake::Task["spotify:get_song_preview_url"].invoke
    #
    # puts "Removing songs with similar capitalizations"
    # Rake::Task["fix_data:song_artist_capitalization"].invoke
    #
    # puts "Done!"
  end
end
