class CreateSongs < ActiveRecord::Migration[5.0]
  def change
    create_table :songs do |t|
      # Basic info
      t.string :spotifyID
      t.string :artist
      t.string :title
      t.string :genre
      t.string :albumArtLink

      # Music Attributes
      t.decimal :danceability 
      t.decimal :energy 
      t.decimal :key 
      t.decimal :loudness 
      t.decimal :mode 
      t.decimal :speechiness 
      t.decimal :acousticness 
      t.decimal :instrumentalness 
      t.decimal :liveness 
      t.decimal :valence 
      t.decimal :tempo 
      t.integer :timeSignature

      t.timestamps
    end
  end
end
