namespace :import_db do
  task import: :environment do
    # puts "Importing data"
    # Rake::Task["csv_import:all"].invoke
    #
    # puts "Shifting Data"
    # Rake::Task["shift_tables:shift"].invoke
    #
    # puts "Fixing artist names"
    # Rake::Task["fix_artist_names:fix"].invoke
    #
    # puts "Hitting API for missing Spotify IDs"
    # Rake::Task["spotifyid_populate:all"].invoke
    #
    # puts "Hitting API for genre, album artwork, and audio features"
    # Rake::Task["audiofeatures_populate:all"].invoke
    #
    # puts "Removing duplicate songs"
    # Rake::Task["duplicate_song_removal:remove"].invoke

    puts "Done!"
  end
end
