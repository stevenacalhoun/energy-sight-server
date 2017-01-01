class AddPopularityToSongs < ActiveRecord::Migration[5.0]
  def change
    change_table :songs do |t|
      t.integer :popularity
    end
  end
end
