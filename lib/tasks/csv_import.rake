require 'csv'

namespace :csv_import do
  task all: :environment do
    Rake::Task["csv_import:seds_data"].invoke
  end

  task seds_data: :environment do
    csv_text = File.read('data/filename.csv')
    csv = CSV.parse(csv_text)
    csv.each do |row|
      # Add each entry
    end
  end
end
