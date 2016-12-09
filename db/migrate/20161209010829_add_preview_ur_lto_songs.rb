class AddPreviewUrLtoSongs < ActiveRecord::Migration[5.0]
  def change
    change_table :songs do |t|
      t.string :preview_url
    end
  end
end
