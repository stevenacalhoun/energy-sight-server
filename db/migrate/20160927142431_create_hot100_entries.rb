class CreateHot100Entries < ActiveRecord::Migration[5.0]
  def change
    create_table :hot100_entries do |t|
      t.string :title
      t.string :artist
      t.integer :peakPos
      t.integer :lastPos
      t.integer :weeks
      t.integer :rank
      t.string :change
      t.string :spotifyID
      t.string :spotifyLink
      t.string :videoLink
      t.datetime :chartWeek

      t.timestamps
    end
  end
end
