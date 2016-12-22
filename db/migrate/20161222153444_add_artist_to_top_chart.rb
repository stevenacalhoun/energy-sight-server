class AddArtistToTopChart < ActiveRecord::Migration[5.0]
  def change
    change_table :top_charts do |t|
      t.string :artist
    end
  end
end
