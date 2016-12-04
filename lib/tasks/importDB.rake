namespace :import_db do
  task import: :environment do
    # puts "Importing data"
    # Rake::Task["csv_import:all"].invoke

    puts "Shifting Data"
    Rake::Task["shift_tables:shift"].invoke

    puts "Fixing artist names"
    Rake::Task["fix_artist_names:fix"].invoke

    puts "Removing duplicate songs"
    Rake::Task["duplicate_song_removal:remove"].invoke

    puts "Spotify stuff"
  end
end
