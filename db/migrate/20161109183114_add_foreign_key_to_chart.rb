class AddForeignKeyToChart < ActiveRecord::Migration[5.0]
  def change
    add_foreign_key :top_charts, :songs
  end
end
