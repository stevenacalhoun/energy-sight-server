class AddSpotifyCountToSongs < ActiveRecord::Migration[5.0]
  def change
    change_table :songs do |t|
      t.integer :spotify_search_count, default: 0
    end
  end
end
