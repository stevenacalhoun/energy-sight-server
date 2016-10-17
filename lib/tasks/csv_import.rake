require 'csv'

namespace :csv_import do
  task all: :environment do
    Rake::Task["csv_import:hot_100_data"].invoke
  end

  task us_data: :environment do
    csv_text = File.read('data/us.csv')
    csv = CSV.parse(csv_text)
    csv.each do |row|
      # Add each entry
      Hot100Entry.create(title: row[0], artist: row[1], peakPos: row[2], lastPos: row[3], weeks: row[4], rank: row[5], change: row[6], spotifyID: row[7], spotifyLink: row[8], videoLink: row[9], chartWeek: row[10], country: 'us')
    end
  end

  task uk_data: :environment do
    csv_text = File.read('data/uk.csv')
    csv = CSV.parse(csv_text)
    csv.each do |row|
      # Add each entry
      Hot100Entry.create(title: row[0], artist: row[1], peakPos: row[2], lastPos: row[3], weeks: row[4], rank: row[5], change: row[6], spotifyID: row[7], spotifyLink: row[8], videoLink: row[9], chartWeek: row[10], country: 'uk')
    end
  end
end
