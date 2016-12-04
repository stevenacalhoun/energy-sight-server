namespace :import_db do
  task fix: :import do
    puts "Impoting data"
    Rake::Task["csv_import:all"].invoke

    puts "Shifting Data"
    Rake::Task["shift_table:shift"]

    puts "Fixing artist names"
    Rake::Task["fix_artist_names:fix"]

    puts "Removing duplicate songs"
    Rake::Task["duplicate_song_removal:remove"]

    puts "Spotify stuff"
  end
end
