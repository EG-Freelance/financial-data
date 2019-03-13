class CreateConstituents < ActiveRecord::Migration
  def change
    create_table :constituents do |t|
      t.date :added
      t.date :removed
      t.string :sym
      t.string :name
      t.string :cik

      t.timestamps null: false
    end
  end
end
