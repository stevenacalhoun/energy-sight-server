class CreateTopCharts < ActiveRecord::Migration[5.0]
  def change
    create_table :top_charts do |t|
      # Links the tables
      t.belongs_to :song, index: true

      # Chart info
      t.integer :rank
      t.string :change
      t.integer :peak_pos
      t.integer :last_pos
      t.integer :weeks
      t.datetime :chart_week
      t.string :country

      t.timestamps
    end
  end
end
