class AddCountryToHot100Entry < ActiveRecord::Migration[5.0]
  def change
    add_column :hot100_entries, :country, :string
  end
end
